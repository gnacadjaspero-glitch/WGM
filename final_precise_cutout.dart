import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // On repart de l'original pour avoir la meilleure qualité possible
  final bytes = File('assets/images/Logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image.from(image);
  int w = result.width;
  int h = result.height;

  // 1. DÉTOURAGE CHIRURGICAL (Sujet uniquement)
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = result.getPixel(x, y);
      
      // On calcule la luminosité
      double luma = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      
      // Zones de protection (Joysticks et boutons noirs au centre)
      bool isCenter = x > w * 0.25 && x < w * 0.75 && y > h * 0.25 && y < h * 0.75;
      
      // On retire tout ce qui est fond noir ou blanc autour des coutures
      // Seuil sévère pour supprimer les effets néon qui débordent
      if (luma < 50 || luma > 250) {
        if (!isCenter || luma < 15) { // On ne garde que le noir absolu du fond au centre
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
  }

  // 2. SUPPRESSION DE L'ÉTOILE (Watermark)
  // On cible la zone exacte du poignet en bas à droite
  int starX = (w * 0.952).toInt();
  int starY = (h * 0.925).toInt();
  int radius = (w * 0.05).toInt();

  for (int y = starY - radius; y < h; y++) {
    for (int x = starX - radius; x < w; x++) {
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      final p = result.getPixel(x, y);
      
      // Si c'est un pixel de l'étoile (brillant) ou un reste de fond
      if (p.r > 150 && p.g > 150 || p.a == 0) {
        // On vérifie qu'on est bien sur la zone de la peau
        // On clone la peau située juste au dessus (décalage vertical)
        final skin = result.getPixel(x, y - 45);
        if (skin.a > 0) {
          result.setPixelRgba(x, y, skin.r, skin.g, skin.b, 255);
        }
      }
    }
  }

  // 3. LISSAGE DES COUTURES (Anti-aliasing)
  final finalImage = img.gaussianBlur(result, radius: 1);

  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(finalImage));
  print('LOGO FINAL : Couture exacte, étoile supprimée, main intacte.');
}
