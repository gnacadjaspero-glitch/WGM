import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

void main() {
  final bytes = File('assets/images/Logo_Final.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image.from(image);
  int w = result.width;
  int h = result.height;
  final random = math.Random();

  // Zone de la fin de la main
  int startX = (w * 0.70).toInt();
  int startY = (h * 0.75).toInt();

  for (int y = startY; y < h; y++) {
    for (int x = startX; x < w; x++) {
      final p = result.getPixel(x, y);
      if (p.a == 0) continue;

      // On calcule une progression de 0 à 1 vers le coin bas-droite
      double progress = ((x - startX) / (w - startX)) * 0.5 + ((y - startY) / (h - startY)) * 0.5;
      
      // On génère un "bruit" aléatoire pour créer l'effet de taches
      double noise = random.nextDouble() * 0.4;
      
      if (progress + noise > 0.85) {
        // Suppression totale avec "dents de scie" aléatoires
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      } else if (progress + noise > 0.6) {
        // Transition par pointillés/taches
        double alphaFactor = (0.85 - (progress + noise)) / 0.25;
        result.setPixelRgba(x, y, p.r, p.g, p.b, (p.a * alphaFactor.clamp(0.0, 1.0)).toInt());
      }
    }
  }

  File('assets/images/Logotest.png').writeAsBytesSync(img.encodePng(result));
  print('Logotest.png généré avec une finition "Pinceau Artistique" (Zéro coupure droite).');
}
