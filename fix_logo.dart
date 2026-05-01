import 'dart:io';
import 'package:image/image.dart';
import 'dart:math' as math;

void main() {
  final inputPath = 'assets/images/Logo.png';
  final outputPath = 'assets/images/Logo_Final.png';

  if (!File(inputPath).existsSync()) {
    print('Input file not found: $inputPath');
    return;
  }

  final bytes = File(inputPath).readAsBytesSync();
  final image = decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image');
    return;
  }

  // Création de l'image de destination avec canal alpha
  final dst = Image(width: image.width, height: image.height, numChannels: 4);
  fill(dst, color: ColorRgba8(0, 0, 0, 0));

  // Zone de l'étoile grise (coin inférieur droit)
  // On définit une zone de sécurité pour ne pas toucher à la manette
  int starAreaX = (image.width * 0.92).toInt();
  int starAreaY = (image.height * 0.92).toInt();

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      
      // 1. Suppression de l'étoile grise dans le coin
      if (x > starAreaX && y > starAreaY) {
        // On vérifie si c'est du gris/proche du fond
        double brightness = (pixel.r + pixel.g + pixel.b) / 3.0;
        if (brightness < 200) continue; // Supprime l'étoile grise
      }

      // 2. Nettoyage de l'arrière-plan (noir ou sombre)
      int maxChannel = [pixel.r, pixel.g, pixel.b].reduce(math.max).toInt();
      if (maxChannel < 40) {
        continue;
      }
      
      // 3. Préservation des couleurs originales
      // On applique juste un léger lissage sur les bords pour la propreté
      if (maxChannel < 60) {
        double alpha = (maxChannel - 40) / (60 - 40);
        dst.setPixel(x, y, ColorRgba8(
          pixel.r.toInt(), 
          pixel.g.toInt(), 
          pixel.b.toInt(), 
          (pixel.a * alpha).toInt()
        ));
      } else {
        dst.setPixel(x, y, pixel);
      }
    }
  }

  // 4. Recadrage automatique
  final trimmed = trim(dst, mode: TrimMode.transparent);

  final pngBytes = encodePng(trimmed);
  File(outputPath).writeAsBytesSync(pngBytes);
  
  print('Logo_Final.png mis à jour : Étoile grise supprimée et fond parfaitement nettoyé.');
}
