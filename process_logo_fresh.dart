import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/Logo.png');
  if (!file.existsSync()) {
    print('Erreur : assets/images/Logo.png introuvable');
    return;
  }

  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  // Création d'une image RGBA
  final result = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 4,
  );

  // 1. RENDRE LE FOND NOIR TRANSPARENT
  // On parcourt toute l'image. Si le pixel est noir (ou très proche du noir), 
  // on le rend transparent.
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      
      // Seuil très bas pour ne pas altérer les couleurs du sujet
      if (p.r < 10 && p.g < 10 && p.b < 10) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        // On garde les couleurs originales EXACTES (luminosité/contraste intacts)
        result.setPixelRgba(x, y, p.r, p.g, p.b, 255);
      }
    }
  }

  // 2. SUPPRESSION DE L'ÉTOILE (Watermark)
  // L'étoile est dans le coin inférieur droit sur la peau.
  // On définit une zone de recherche pour le filigrane.
  int startX = (image.width * 0.90).toInt();
  int startY = (image.height * 0.85).toInt();

  for (var y = startY; y < image.height; y++) {
    for (var x = startX; x < image.width; x++) {
      final p = result.getPixel(x, y);
      if (p.a == 0) continue; // On ignore le fond déjà transparent

      // L'étoile est plus claire/blanche que la peau. 
      // On détecte les pixels "filigrane".
      if (p.r > 130 && p.g > 120 && p.b > 120) {
        // On "guérit" en clonant la peau saine à gauche (décalage de 40 pixels)
        int srcX = x - 40;
        if (srcX < 0) srcX = 0;
        final skin = result.getPixel(srcX, y);
        
        // Si le pixel source est bien de la peau (pas transparent)
        if (skin.a > 0) {
          result.setPixelRgba(x, y, skin.r, skin.g, skin.b, 255);
        }
      }
    }
  }

  // 3. SAUVEGARDE
  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(result));
  print('LOGO_FINAL RE-CRÉÉ DE ZÉRO : Fond transparent et étoile supprimée sans toucher à la lumière.');
}
