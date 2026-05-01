import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static const String keyPostes = 'chronoTvPostes';
  static const String keySessions = 'chronoTvSessions';
  static const String keyRecettes = 'chronoTvRecettes';

  // Streams pour notifier les changements
  static final _postesStreamController = StreamController<List<Poste>>.broadcast();
  static Stream<List<Poste>> get postesStream => _postesStreamController.stream;

  static final _sessionsStreamController = StreamController<Map<String, Session>>.broadcast();
  static Stream<Map<String, Session>> get sessionsStream => _sessionsStreamController.stream;

  static final _recettesStreamController = StreamController<List<Recette>>.broadcast();
  static Stream<List<Recette>> get recettesStream => _recettesStreamController.stream;

  // --- POSTES ---
  static Future<List<Poste>> getPostes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(keyPostes);
    if (data == null) return [];
    try {
      final List decoded = json.decode(data);
      return decoded.map((e) => Poste.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> savePostes(List<Poste> postes) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(postes.map((e) => e.toMap()).toList());
    await prefs.setString(keyPostes, data);
    _postesStreamController.add(postes); // Notifier les écouteurs
  }

  // --- SESSIONS ---
  static Future<Map<String, Session>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(keySessions);
    if (data == null) return {};
    try {
      final Map<String, dynamic> decoded = json.decode(data);
      return decoded.map((key, value) => MapEntry(key, Session.fromMap(value)));
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveSessions(Map<String, Session> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(sessions.map((key, value) => MapEntry(key, value.toMap())));
    await prefs.setString(keySessions, data);
    _sessionsStreamController.add(sessions); // Notifier les écouteurs
  }

  // --- RECETTES ---
  static Future<List<Recette>> getRecettes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(keyRecettes);
    if (data == null) return [];
    try {
      final List decoded = json.decode(data);
      return decoded.map((e) => Recette.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addRecette(Recette recette) async {
    final recettes = await getRecettes();
    recettes.add(recette);
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(recettes.map((e) => e.toMap()).toList());
    await prefs.setString(keyRecettes, data);
    _recettesStreamController.add(recettes); // Notifier les écouteurs
  }
  
  static Future<void> saveRecettes(List<Recette> recettes) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(recettes.map((e) => e.toMap()).toList());
    await prefs.setString(keyRecettes, data);
    _recettesStreamController.add(recettes);
  }
}
