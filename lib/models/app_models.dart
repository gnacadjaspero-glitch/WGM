class Poste {
  final String id;
  final String nom;
  final List<Tarif> tarifs;

  Poste({required this.id, required this.nom, required this.tarifs});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Poste && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'tarifs': tarifs.map((x) => x.toMap()).toList(),
    };
  }

  factory Poste.fromMap(Map<String, dynamic> map) {
    return Poste(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      tarifs: List<Tarif>.from(map['tarifs']?.map((x) => Tarif.fromMap(x)) ?? []),
    );
  }
}

class Tarif {
  final String id;
  final int duree; // en minutes
  final int prix;

  Tarif({required this.id, required this.duree, required this.prix});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tarif && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Label généré automatiquement
  String get label => '$duree min - $prix CFA';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'duree': duree,
      'prix': prix,
    };
  }

  factory Tarif.fromMap(Map<String, dynamic> map) {
    return Tarif(
      id: map['id'] ?? '',
      duree: map['duree']?.toInt() ?? 0,
      prix: map['prix']?.toInt() ?? 0,
    );
  }
}

class Session {
  final String posteId;
  final String posteNom;
  final DateTime endAt;
  final int totalDuree;
  final int totalPrix;
  final String lastTarifLabel;
  final bool isCoupure;

  Session({
    required this.posteId,
    required this.posteNom,
    required this.endAt,
    required this.totalDuree,
    required this.totalPrix,
    required this.lastTarifLabel,
    this.isCoupure = false,
  });

  bool get isActive => endAt.isAfter(DateTime.now()) || isCoupure;

  Map<String, dynamic> toMap() {
    return {
      'posteId': posteId,
      'posteNom': posteNom,
      'endAt': endAt.millisecondsSinceEpoch,
      'totalDuree': totalDuree,
      'totalPrix': totalPrix,
      'lastTarifLabel': lastTarifLabel,
      'isCoupure': isCoupure,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      posteId: map['posteId'] ?? '',
      posteNom: map['posteNom'] ?? '',
      endAt: DateTime.fromMillisecondsSinceEpoch(map['endAt'] ?? 0),
      totalDuree: map['totalDuree']?.toInt() ?? 0,
      totalPrix: map['totalPrix']?.toInt() ?? 0,
      lastTarifLabel: map['lastTarifLabel'] ?? '',
      isCoupure: map['isCoupure'] ?? false,
    );
  }

  Session copyWith({
    String? posteId,
    String? posteNom,
    DateTime? endAt,
    int? totalDuree,
    int? totalPrix,
    String? lastTarifLabel,
    bool? isCoupure,
  }) {
    return Session(
      posteId: posteId ?? this.posteId,
      posteNom: posteNom ?? this.posteNom,
      endAt: endAt ?? this.endAt,
      totalDuree: totalDuree ?? this.totalDuree,
      totalPrix: totalPrix ?? this.totalPrix,
      lastTarifLabel: lastTarifLabel ?? this.lastTarifLabel,
      isCoupure: isCoupure ?? this.isCoupure,
    );
  }
}

class Recette {
  final String id;
  final String posteId;
  final String posteNom;
  final int duree;
  final int prix;
  final DateTime createdAt;
  final String tarifLabel; // Ajouté pour le rapport PDF

  Recette({
    required this.id,
    required this.posteId,
    required this.posteNom,
    required this.duree,
    required this.prix,
    required this.createdAt,
    required this.tarifLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'posteId': posteId,
      'posteNom': posteNom,
      'duree': duree,
      'prix': prix,
      'createdAt': createdAt.toIso8601String(),
      'tarifLabel': tarifLabel,
    };
  }

  factory Recette.fromMap(Map<String, dynamic> map) {
    return Recette(
      id: map['id'] ?? '',
      posteId: map['posteId'] ?? '',
      posteNom: map['posteNom'] ?? '',
      duree: map['duree']?.toInt() ?? 0,
      prix: map['prix']?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      tarifLabel: map['tarifLabel'] ?? '${map['duree']} min',
    );
  }
}
