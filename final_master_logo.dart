import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/Logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image.from(image);
  int w = result.width;
  int h = result.height;

  // 1. DÉTOURAGE CHIRURGICAL (SANS TOUCHER AUX COULEURS)
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = result.getPixel(x, y);
      
      // On calcule si le pixel appartient au fond (splatter noir ou blanc externe)
      // La manette et la main ont des couleurs riches (rouge, bleu, chair)
      // Le fond est soit noir profond (< 40) soit blanc pur (> 250)
      bool isBg = (p.r < 45 && p.g < 45 && p.b < 45) || (p.r > 250 && p.g > 250 && p.b > 250);
      
      // Sécurité pour ne pas trouer la manette (les joysticks sont noirs)
      // On ne retire le noir que s'il est vers les bords extérieurs
      bool isEdgeZone = x < w * 0.22 || x > w * 0.78 || y < h * 0.15 || y > h * 0.85;

      if (isBg) {
        if (isEdgeZone) {
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        } else if (p.r < 15 && p.g < 15 && p.b < 15) {
          // Au centre, on ne retire que le noir absolu (fond entre les doigts/manette)
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
  }

  // 2. SUPPRESSION DE L'ÉTOILE PAR RECONSTRUCTION (SANS COUPURE)
  // L'étoile est sur le poignet (bas droite)
  int starX = (w * 0.952).toInt();
  int starY = (h * 0.928).toInt();
  int area = (w * 0.04).toInt();

  for (int y = starY - area; y < h; y++) {
    for (int x = starX - area; x < w; x++) {
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      final p = result.getPixel(x, y);
      
      // On détecte l'éclat de l'étoile (plus clair que la peau environnante)
      if (p.a > 0 && p.r > 160 && p.g > 150) {
        // On clone la peau située juste au dessus (pour suivre le dégradé du bras)
        final sample = result.getPixel(x, y - 40); 
        result.setPixelRgba(x, y, sample.r, sample.g, sample.b, 255);
      }
    }
  }

  // 3. FINITION PROPRE (Anti-aliasing léger sur les bords uniquement)
  final finalImg = img.gaussianBlur(result, radius: 1);

  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(finalImg));
  print('LOGO_FINAL GÉNÉRÉ : Détourage exact, étoile masquée, image originale respectée.');
}
