import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/Logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 4,
  );

  // Uniquement suppression du fond noir (seuil très bas)
  // AUCUNE autre modification (on garde l'étoile et les couleurs telles quelles)
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      
      // Si le pixel est noir pur ou extrêmement proche
      if (p.r < 5 && p.g < 5 && p.b < 5) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        result.setPixelRgba(x, y, p.r, p.g, p.b, 255);
      }
    }
  }

  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(result));
  print('TERMINÉ : Uniquement suppression du background noir effectuée.');
}
