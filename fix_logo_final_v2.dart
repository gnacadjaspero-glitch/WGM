import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/Logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  final result = img.Image.from(image);
  int w = result.width;
  int h = result.height;

  // 1. RENDRE LE FOND TRANSPARENT (Sans toucher au sujet)
  // On identifie le fond (souvent les coins sont le fond)
  // On assume que le fond est soit blanc pur soit noir pur selon le fichier source
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final pixel = result.getPixel(x, y);
      
      // Si le pixel est blanc (fond de l'image fournie)
      if (pixel.r > 245 && pixel.g > 245 && pixel.b > 245) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      }
      // Si le pixel est noir (fond de l'original possible)
      else if (pixel.r < 10 && pixel.g < 10 && pixel.b < 10) {
        result.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  // 2. SUPPRESSION DE L'ÉTOILE (Surgical Patch)
  // L'étoile se trouve en bas à droite sur le bras.
  // On va définir une zone de travail autour de l'étoile.
  // Zone estimée : 90% à 100% largeur, 85% à 95% hauteur.
  int xStart = (w * 0.90).toInt();
  int yStart = (h * 0.82).toInt();
  int xEnd = (w * 0.99).toInt();
  int yEnd = (h * 0.96).toInt();

  for (var y = yStart; y < yEnd; y++) {
    for (var x = xStart; x < xEnd; x++) {
      final pixel = result.getPixel(x, y);
      
      // On détecte la couleur de l'étoile (plus sombre que la peau ou éclat blanc/brun)
      // On ne veut pas supprimer les pixels de peau sains.
      // On va plutôt "tamponner" : copier la texture de 20 pixels à gauche.
      
      // Si on est dans la zone de l'étoile (on détecte une différence de teinte ou éclat)
      // Pour être sûr, on va patcher toute la petite zone de l'étoile en clonant 
      // la peau située juste à gauche (x - 40 pixels)
      
      // Détection de l'étoile : couleur spécifique ou simplement zone cible
      // Ici l'étoile est sombre sur la peau claire.
      if (pixel.r < 150 || (pixel.r > 200 && pixel.g > 200)) { 
        // Échantillon de peau saine à gauche
        final sample = result.getPixel(x - 50, y); 
        result.setPixelRgba(x, y, sample.r, sample.g, sample.b, 255);
      }
    }
  }

  // On applique un léger flou local uniquement sur la zone patchée pour lisser
  for (var i = 0; i < 2; i++) {
    for (var y = yStart + 1; y < yEnd - 1; y++) {
      for (var x = xStart + 1; x < xEnd - 1; x++) {
        final p1 = result.getPixel(x, y);
        final p2 = result.getPixel(x - 1, y);
        final p3 = result.getPixel(x + 1, y);
        final p4 = result.getPixel(x, y - 1);
        final p5 = result.getPixel(x, y + 1);
        
        result.setPixelRgba(x, y, 
          (p1.r + p2.r + p3.r + p4.r + p5.r) ~/ 5,
          (p1.g + p2.g + p3.g + p4.g + p5.g) ~/ 5,
          (p1.b + p2.b + p3.b + p4.b + p5.b) ~/ 5,
          255
        );
      }
    }
  }

  File('assets/images/Logo_Final.png').writeAsBytesSync(img.encodePng(result));
  print('LOGO FINAL : Étoile supprimée par clonage de texture, fond transparent, luminosité préservée.');
}
