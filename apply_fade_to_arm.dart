import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/Logo_Final.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image.from(image);
  int w = result.width;
  int h = result.height;

  // On cible la zone du bas de l'avant-bras (coin inférieur droit)
  // On va appliquer un dégradé de transparence (Alpha) et une courbure
  
  int fadeZoneHeight = (h * 0.15).toInt(); // Les 15% du bas
  int startY = h - fadeZoneHeight;

  for (int y = startY; y < h; y++) {
    // Calcul de l'opacité (de 1.0 à 0.0)
    double opacity = 1.0 - ((y - startY) / fadeZoneHeight);
    
    // Pour ajouter une courbure, on décale le début du fondu horizontalement
    for (int x = 0; x < w; x++) {
      final p = result.getPixel(x, y);
      if (p.a == 0) continue;

      // On applique la nouvelle opacité
      // On multiplie l'opacité existante par notre facteur de dégradé
      int newAlpha = (p.a * opacity).toInt();
      
      // Optionnel : On peut aussi "arrondir" le coin en augmentant le fondu sur la droite
      if (x > w * 0.85) {
        double xOpacity = 1.0 - ((x - (w * 0.85)) / (w * 0.15));
        newAlpha = (newAlpha * xOpacity).toInt();
      }

      result.setPixelRgba(x, y, p.r, p.g, p.b, newAlpha);
    }
  }

  File('assets/images/Logotest.png').writeAsBytesSync(img.encodePng(result));
  print('Logotest.png créé avec un effet de fondu artistique sur le bas du bras.');
}
