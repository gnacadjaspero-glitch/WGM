import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/Logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image.from(image);
  int w = result.width;
  int h = result.height;

  // 1. SUPPRESSION DU FOND (Blanc et Nuage Noir)
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = result.getPixel(x, y);
      
      // Suppression du fond blanc
      if (p.r > 240 && p.g > 240 && p.b > 240) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      // Suppression du nuage noir (splatter)
      double luma = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      if (luma < 65) {
        // On protège le centre (joysticks/boutons) pour ne pas faire de trous
        bool isInsideSubject = x > w * 0.28 && x < w * 0.72 && y > h * 0.25 && y < h * 0.75;
        
        if (!isInsideSubject) {
          // C'est le nuage noir extérieur
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        } else if (luma < 15) {
          // Noir profond entre les doigts ou les boutons
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
  }

  // 2. CAMOUFLAGE DE L'ÉTOILE (Watermark sur le poignet)
  int starX = (w * 0.955).toInt();
  int starY = (h * 0.925).toInt();
  int area = (w * 0.05).toInt();
  
  for (int y = starY - area; y < h; y++) {
    for (int x = starX - area; x < w; x++) {
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      final p = result.getPixel(x, y);
      if (p.a == 0) continue;

      // On détecte les pixels clairs de l'étoile sur la peau plus foncée
      if (p.r > 160 && p.g > 150) { 
        // On clone la texture de peau saine située juste à gauche
        final skin = result.getPixel(x - 45, y);
        result.setPixelRgba(x, y, skin.r, skin.g, skin.b, 255);
      }
    }
  }

  // 3. LISSAGE DES CONTOURS
  final finalImage = img.gaussianBlur(result, radius: 1);

  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(finalImage));
  print('DÉTOURAGE TERMINÉ : Fond supprimé, étoile masquée, main intacte.');
}
