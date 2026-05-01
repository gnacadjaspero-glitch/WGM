import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/app_models.dart';

import 'package:flutter/services.dart';

class AuditService {
  static Future<String> get _localPath async {
    String path;
    if (Platform.isWindows) {
      // Sur PC : Dossier système AppData (Caché par défaut)
      final directory = await getApplicationSupportDirectory(); // Pointe vers AppData/Roaming
      path = '${directory.path}/Audit_Logs';
    } else if (Platform.isAndroid) {
      // Sur Phone : Dossier Documents Public mais masqué par le "."
      path = '/storage/emulated/0/Documents/.wgm_audit';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      path = '${directory.path}/.wgm_audit';
    }

    final dir = Directory(path);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        // Fallback si permission refusée sur Android public
        final fallbackDir = await getApplicationDocumentsDirectory();
        path = '${fallbackDir.path}/.wgm_audit';
        final fDir = Directory(path);
        if (!await fDir.exists()) await fDir.create(recursive: true);
      }
    }
    return path;
  }

  static Future<void> logAction(String message) async {
    try {
      final path = await _localPath;
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('$path/Journal_$dateStr.txt');
      final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append, flush: true);
    } catch (e) {
      print("Erreur Audit Log: $e");
    }
  }

  static Future<void> updateDailyReport(List<Recette> recettes) async {
    try {
      final path = await _localPath;
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('$path/Rapport_Recettes_$dateStr.pdf');
      final pdf = pw.Document();

      // Couleurs du Logo (Néon)
      final neonCyan = PdfColor.fromInt(0xff00ffff);
      final neonPink = PdfColor.fromInt(0xffff00ff);
      final darkBg = PdfColor.fromInt(0xff0a0a0f); // Fond très sombre pour faire ressortir le néon

      // Chargement du logo
      final ByteData bytes = await rootBundle.load('assets/images/Logo_Final.png');
      final Uint8List logoData = bytes.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoData);

      // Regroupement des données par Poste
      Map<String, List<Recette>> groupedByPoste = {};
      int totalGlobal = 0;
      for (var r in recettes) {
        groupedByPoste.putIfAbsent(r.posteNom, () => []).add(r);
        totalGlobal += r.prix;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // HEADER STYLE NÉON
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                decoration: pw.BoxDecoration(
                  color: darkBg,
                  borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(10), topRight: pw.Radius.circular(10)),
                  border: pw.Border(bottom: pw.BorderSide(color: neonCyan, width: 2)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // BLOC GAUCHE : LOGO (Largeur fixe pour équilibrer le centrage)
                    pw.SizedBox(
                      width: 160,
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: 70,
                          height: 70,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: neonCyan, width: 2),
                          ),
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.ClipOval(
                            child: pw.Center(
                              child: pw.AspectRatio(
                                aspectRatio: 1,
                                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // BLOC CENTRE : TOTAL (Centré par rapport à la page)
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('RECETTE TOTALE', style: pw.TextStyle(color: neonCyan, fontSize: 8, letterSpacing: 2, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text('${NumberFormat('#,###', 'fr_FR').format(totalGlobal).replaceAll('\u00A0', ' ')} CFA', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 26)),
                          pw.SizedBox(height: 5),
                          pw.Container(height: 1.5, width: 60, color: neonPink),
                        ],
                      ),
                    ),

                    // BLOC DROITE : INFOS (Largeur fixe pour équilibrer le centrage)
                    pw.SizedBox(
                      width: 160,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('WINNER GAME MANAGER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.white)),
                          pw.SizedBox(height: 2),
                          pw.Text('RAPPORT OFFICIEL', style: pw.TextStyle(fontSize: 9, color: neonCyan, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
                          pw.SizedBox(height: 12),
                          pw.Text('DATE: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // BOUCLE SUR CHAQUE POSTE
              ...groupedByPoste.entries.map((entry) {
                final posteNom = entry.key;
                final posteSessions = entry.value;
                final posteTotal = posteSessions.fold(0, (sum, r) => sum + r.prix);

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Titre du Poste + Total du poste
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(posteNom.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text('CUMUL: ${NumberFormat('#,###', 'fr_FR').format(posteTotal).replaceAll('\u00A0', ' ')} CFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Détail des sessions pour ce poste
                    pw.TableHelper.fromTextArray(
                      border: null,
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                      headerDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                      headers: ['HEURE', 'DETAILS', 'PRIX'],
                      data: posteSessions.map((r) => [
                        DateFormat('HH:mm').format(r.createdAt),
                        r.tarifLabel.toUpperCase(),
                        '${NumberFormat('#,###', 'fr_FR').format(r.prix).replaceAll('\u00A0', ' ')} CFA'
                      ]).toList(),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(80),
                        1: const pw.FlexColumnWidth(),
                        2: const pw.FixedColumnWidth(100),
                      },
                    ),
                    pw.SizedBox(height: 15), // Espace avant le poste suivant
                  ],
                );
              }).toList(),

              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 20),
              
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('CERTIFIE CONFORME - WINNER GAME MANAGER', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold)),
              ),
            ];
          },
        ),
      );

      await file.writeAsBytes(await pdf.save());
    } catch (e) {
      print("Erreur PDF Report: $e");
    }
  }
}
