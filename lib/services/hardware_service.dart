import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HardwareService {
  // IP Fixe imposée : 192.168.100.1
  static const String _baseUrl = "192.168.100.1";
  // Clé complexe de sécurité (doit correspondre exactement à l'ESP32)
  static const String _secretKey = r"X9#kL2!vP5*qZ8$mN4@yT1";

  static Future<void> init() async {}

  static String get currentIp => _baseUrl;

  /// Envoie une instruction d'activation au boitier ESP32 avec clé de sécurité complexe
  static Future<bool> sendActivation(String posteId, int minutes) async {
    try {
      final response = await http.get(
        Uri.parse('http://$_baseUrl/activate?id=$posteId&time=$minutes&key=$_secretKey'),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      print("Erreur Hardware (Activation): $e");
      return false; 
    }
  }

  /// Envoie une instruction d'arrêt au boitier ESP32 avec clé de sécurité
  static Future<bool> sendDeactivation(String posteId) async {
    try {
      final response = await http.get(
        Uri.parse('http://$_baseUrl/stop?id=$posteId&key=$_secretKey'),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      print("Erreur Hardware (Arrêt): $e");
      return false;
    }
  }

  /// Récupère l'état de tous les postes (incluant les coupures)
  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://$_baseUrl/status'),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> statusMap = {};
        for (var poste in data['postes']) {
          statusMap[poste['id']] = {
            'remains': poste['remains'],
            'isCoupure': poste['isCoupure'] ?? false,
          };
        }
        return statusMap;
      }
    } catch (e) {
      // Silence sur les timeouts de status
    }
    return null;
  }

  /// Relance une session après coupure
  static Future<bool> resumeAfterCoupure(String posteId) async {
    try {
      final response = await http.get(
        Uri.parse('http://$_baseUrl/resume?id=$posteId&key=$_secretKey'),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      print("Erreur Hardware (Resume): $e");
      return false;
    }
  }

  /// Envoie une mise à jour firmware (.bin)
  static Future<bool> sendUpdate(List<int> bytes) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://$_baseUrl/update'));
      request.files.add(http.MultipartFile.fromBytes('update', bytes, filename: 'update.bin'));
      request.fields['key'] = _secretKey;
      
      var response = await request.send().timeout(const Duration(minutes: 5));
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur Mise à jour: $e");
      return false;
    }
  }
}
