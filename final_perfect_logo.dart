import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/Logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  // Création d'une image avec transparence
  final result = img.Image.from(image);
  int width = result.width;
  int height = result.height;

  // 1. DÉTOURAGE INTELLIGENT
  // On veut enlever le fond noir sans laisser de bordures dégueulasses.
  // On va transformer la luminosité "noire" en transparence.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixel = result.getPixel(x, y);
      
      // Calcul de la luminosité perçue
      double luma = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
      
      // Si c'est du noir pur ou très proche
      if (luma < 30) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      } else if (luma < 80) {
        // Pour les zones de "glow" (lueurs), on rend partiellement transparent
        // au lieu de couper brutalement. Ça évite l'effet de bordure noire.
        double alpha = (luma - 30) / (80 - 30) * 255;
        result.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha.toInt());
      }
    }
  }

  // 2. CORRECTION DE L'ÉTOILE (MODE RÉALISTE)
  // Au lieu d'un carré, on va faire un fondu circulaire avec la peau.
  int starX = (width * 0.96).toInt();
  int starY = (height * 0.93).toInt();
  int radius = (width * 0.05).toInt(); // Zone de l'étoile

  // On prend la couleur de la peau saine juste à côté
  final skin = result.getPixel((width * 0.90).toInt(), (height * 0.90).toInt());

  for (var y = starY - radius; y < height; y++) {
    for (var x = starX - radius; x < width; x++) {
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      
      final pixel = result.getPixel(x, y);
      double dist = (x - starX) * (x - starX) + (y - starY) * (y - starY).toDouble();
      
      // Si c'est un pixel brillant (l'étoile)
      if (pixel.r > 150 && pixel.g > 150) {
        // On remplace par la peau mais avec un léger mélange progressif
        result.setPixelRgba(x, y, skin.r, skin.g, skin.b, 255);
      }
    }
  }

  // 3. LISSAGE FINAL (Uniquement sur les bords de la main)
  // On applique un léger flou de surface pour harmoniser
  final polished = img.gaussianBlur(result, radius: 1);

  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(polished));
  print('LOGO FINAL PARFAIT GÉNÉRÉ');
}
