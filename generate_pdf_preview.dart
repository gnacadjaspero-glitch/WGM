import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final mockup = img.Image(width: 800, height: 1100);
  img.fill(mockup, color: img.ColorRgb8(255, 255, 255));

  final darkBg = img.ColorRgb8(10, 10, 15);
  final neonCyan = img.ColorRgb8(0, 255, 255);
  final neonPink = img.ColorRgb8(255, 0, 255);
  final textDark = img.ColorRgb8(20, 20, 20);
  final textGray = img.ColorRgb8(120, 120, 120);
  final bgGrey = img.ColorRgb8(245, 245, 245);

  // 1. HEADER (VRAI CENTRAGE)
  img.fillRect(mockup, x1: 0, y1: 0, x2: 800, y2: 180, color: darkBg);
  img.drawLine(mockup, x1: 0, y1: 178, x2: 800, y2: 178, color: neonCyan, thickness: 2);
  
  // LOGO CIRCULAIRE (Gauche)
  try {
    final logoBytes = File('assets/images/Logo_Final.png').readAsBytesSync();
    var logo = img.decodeImage(logoBytes);
    if (logo != null) {
      int size = 90;
      double scale = size / (logo.width > logo.height ? logo.width : logo.height);
      int newW = (logo.width * scale).toInt();
      int newH = (logo.height * scale).toInt();
      logo = img.copyResize(logo, width: newW, height: newH, interpolation: img.Interpolation.cubic);
      img.drawCircle(mockup, x: 95, y: 90, radius: 52, color: neonCyan);
      img.compositeImage(mockup, logo, dstX: 95 - (newW ~/ 2), dstY: 90 - (newH ~/ 2));
    }
  } catch (e) {}

  // TOTAL AU CENTRE (CENTRAGE FORCÉ)
  img.drawString(mockup, 'RECETTE TOTALE', font: img.arial14, x: 325, y: 40, color: neonCyan);
  img.drawString(mockup, '3 800 CFA', font: img.arial24, x: 315, y: 65, color: img.ColorRgb8(255, 255, 255));
  img.drawLine(mockup, x1: 345, y1: 105, x2: 435, y2: 105, color: neonPink, thickness: 2);

  // INFOS À DROITE (PARFAITEMENT CALÉES)
  img.drawString(mockup, 'WINNER GAME MANAGER', font: img.arial14, x: 565, y: 45, color: img.ColorRgb8(255, 255, 255));
  img.drawString(mockup, 'RAPPORT OFFICIEL', font: img.arial14, x: 615, y: 70, color: neonCyan);
  img.drawString(mockup, 'DATE: 22/05/2024', font: img.arial14, x: 630, y: 115, color: textGray);

  int currentY = 220;

  void drawPosteSection(String nom, String total, List<List<String>> rows) {
    img.fillRect(mockup, x1: 40, y1: currentY, x2: 760, y2: currentY + 35, color: bgGrey);
    img.drawString(mockup, nom.toUpperCase(), font: img.arial14, x: 55, y: currentY + 12, color: darkBg);
    img.drawString(mockup, 'CUMUL: $total', font: img.arial14, x: 580, y: currentY + 12, color: textDark);
    currentY += 50;
    img.drawString(mockup, 'HEURE', font: img.arial14, x: 60, y: currentY, color: textGray);
    img.drawString(mockup, 'DETAILS', font: img.arial14, x: 250, y: currentY, color: textGray);
    img.drawString(mockup, 'PRIX', font: img.arial14, x: 620, y: currentY, color: textGray);
    currentY += 25;
    img.drawLine(mockup, x1: 50, y1: currentY, x2: 740, y2: currentY, color: bgGrey);
    currentY += 10;
    for (var row in rows) {
      img.drawString(mockup, row[0], font: img.arial14, x: 60, y: currentY, color: textGray);
      img.drawString(mockup, row[1], font: img.arial14, x: 250, y: currentY, color: textDark);
      img.drawString(mockup, row[2], font: img.arial14, x: 620, y: currentY, color: textDark);
      currentY += 30;
    }
    currentY += 20;
  }

  drawPosteSection('Poste 1', '1 500 CFA', [['09:15', 'Forfait 1 Heure', '500 CFA'], ['14:20', 'Forfait 2 Heures', '1000 CFA']]);
  drawPosteSection('Poste 3', '2 300 CFA', [['10:00', 'Forfait 1 Heure', '500 CFA'], ['16:45', 'Forfait 3 Heures', '1500 CFA']]);

  img.drawString(mockup, 'CERTIFIE CONFORME - WINNER GAME MANAGER', font: img.arial14, x: 40, y: 1050, color: textGray);

  File('assets/images/PDF.jpg').writeAsBytesSync(img.encodeJpg(mockup));
}
