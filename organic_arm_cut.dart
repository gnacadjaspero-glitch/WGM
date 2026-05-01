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

  // On définit le point de pivot de la courbe (où le bras commence à s'effacer)
  double pivotX = w * 0.75;
  double pivotY = h * 0.80;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = result.getPixel(x, y);
      if (p.a == 0) continue;

      // On calcule la distance par rapport au coin inférieur droit de manière incurvée
      // On crée une ellipse imaginaire pour couper le bras
      double dx = (x - pivotX) / (w - pivotX);
      double dy = (y - pivotY) / (h - pivotY);
      
      // Equation de l'ellipse de découpe
      double distance = math.sqrt(math.max(0, dx * dx + dy * dy));

      if (x > pivotX && y > pivotY) {
        // Zone de découpe
        if (distance > 1.0) {
          // Hors de la courbe : Totalement transparent
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        } else if (distance > 0.6) {
          // Transition douce (Feathering)
          double alphaFactor = 1.0 - ((distance - 0.6) / 0.4);
          // Courbe de transition non-linéaire pour plus de douceur
          alphaFactor = math.pow(alphaFactor, 2.0).toDouble(); 
          
          result.setPixelRgba(x, y, p.r, p.g, p.b, (p.a * alphaFactor).toInt());
        }
      }
    }
  }

  File('assets/images/Logotest.png').writeAsBytesSync(img.encodePng(result));
  print('Logotest.png généré avec une découpe organique incurvée.');
}
