import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/Logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image(width: image.width, height: image.height, numChannels: 4);
  int w = image.width;
  int h = image.height;

  // 1. DÉTOURAGE CHIRURGICAL DU FOND
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      
      // Le fond est strictement noir (0,0,0) ou presque.
      // On utilise un seuil très bas pour ne pas manger les ombres du bras ou les joysticks.
      if (p.r < 8 && p.g < 8 && p.b < 8) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        // On copie le pixel EXACT pour respecter la lumière et le contraste originaux
        result.setPixelRgba(x, y, p.r, p.g, p.b, 255);
      }
    }
  }

  // 2. CAMOUFLAGE DE L'ÉTOILE (Inpainting par texture)
  // On cible le filigrane en bas à droite sur l'avant-bras.
  int starX = (w * 0.93).toInt();
  int starY = (h * 0.85).toInt();

  for (int y = starY; y < h; y++) {
    for (int x = starX; x < w; x++) {
      final p = result.getPixel(x, y);
      if (p.a == 0) continue;

      // On détecte les pixels blancs/gris du filigrane
      if (p.r > 140 && p.g > 140 && p.b > 140) {
        // On clone la peau saine située 80 pixels à gauche
        // Cela préserve le dégradé et le grain de la peau parfaitement.
        int srcX = x - 80;
        if (srcX < 0) srcX = 0;
        final skin = result.getPixel(srcX, y);
        result.setPixelRgba(x, y, skin.r, skin.g, skin.b, 255);
      }
    }
  }

  // Sauvegarde du résultat final
  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(result));
  print('LOGO_FINAL GÉNÉRÉ : Arrière-plan supprimé proprement et étoile camouflée.');
}
