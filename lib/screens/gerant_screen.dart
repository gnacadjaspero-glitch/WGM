import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../widgets/notifications.dart';
import 'login_screen.dart';
import '../services/wifi_service.dart';
import '../services/hardware_service.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audit_service.dart';

class GerantScreen extends StatefulWidget {
  const GerantScreen({super.key});

  @override
  State<GerantScreen> createState() => _GerantScreenState();
}

class _GerantScreenState extends State<GerantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _wifiName;
  List<Poste> _postes = [];
  Map<String, Session> _sessions = {};
  List<Recette> _recettes = [];
  
  Poste? _selectedPoste;
  Tarif? _selectedTarif;
  
  Timer? _timer;
  Timer? _syncTimer;
  StreamSubscription? _postesSub, _sessionsSub, _recettesSub;
  DateTime _selectedDate = DateTime.now();
  
  // Gestion du son
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _alertedSessions = {}; // Pour ne pas rejouer le son en boucle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    
    // Écoute des flux de données avec mise à jour automatique de l'UI
    _postesSub = StorageService.postesStream.listen((data) {
      if (mounted) setState(() => _postes = data);
    });
    _sessionsSub = StorageService.sessionsStream.listen((data) {
      if (mounted) setState(() => _sessions = data);
    });
    _recettesSub = StorageService.recettesStream.listen((data) {
      if (mounted) setState(() => _recettes = data);
    });
    
    // Rafraîchissement visuel du chrono (1fps)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkTimerAlerts();
      if (mounted) setState(() {}); 
    });
    
    // Synchronisation matérielle (toutes les 5s)
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) => _syncWithHardware());

    // Surveillance du WiFi
    WifiService.wifiNameStream.listen((name) {
      if (mounted) setState(() => _wifiName = name);
    });
    
    WifiService.checkWifi();
    _syncWithHardware();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    _postesSub?.cancel(); 
    _sessionsSub?.cancel(); 
    _recettesSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final postes = await StorageService.getPostes();
    final sessions = await StorageService.getSessions();
    final recettes = await StorageService.getRecettes();
    if (mounted) {
      setState(() { 
        _postes = postes; 
        _sessions = sessions; 
        _recettes = recettes; 
        if (_postes.isNotEmpty && _selectedPoste == null) {
          _selectedPoste = _postes.first;
        }
      });
    }
  }

  Future<void> _syncWithHardware() async {
    final hwStatus = await HardwareService.getStatus();
    if (hwStatus == null) return;

    bool changed = false;
    final newSessions = Map<String, Session>.from(_sessions);

    hwStatus.forEach((id, data) {
      final remains = data['remains'] as int;
      final isCoupure = data['isCoupure'] as bool;

      final poste = _postes.firstWhere(
        (p) => p.nom.replaceAll('POSTE ', 'P') == id, 
        orElse: () => Poste(id: '', nom: '', tarifs: [])
      );
      
      if (poste.id.isNotEmpty) {
        if (remains > 0) {
          final targetEndAt = DateTime.now().add(Duration(seconds: remains));
          if (!newSessions.containsKey(poste.id)) {
            newSessions[poste.id] = Session(
              posteId: poste.id,
              posteNom: poste.nom,
              endAt: targetEndAt,
              totalDuree: 0,
              totalPrix: 0,
              lastTarifLabel: "Hardware",
              isCoupure: isCoupure,
            );
            changed = true;
          } else {
            final session = newSessions[poste.id]!;
            // Si l'état de coupure change, ou si le temps dévie trop (>2s)
            // En mode coupure, on force targetEndAt pour que (endAt - now) = remains constant
            bool shouldUpdate = session.isCoupure != isCoupure;
            if (!shouldUpdate) {
              final currentDiff = session.endAt.difference(DateTime.now()).inSeconds;
              if ((currentDiff - remains).abs() > 2) {
                shouldUpdate = true;
              }
            }

            if (shouldUpdate) {
              newSessions[poste.id] = session.copyWith(isCoupure: isCoupure, endAt: targetEndAt);
              changed = true;
            }
          }
        } else if (newSessions.containsKey(poste.id)) {
          newSessions.remove(poste.id);
          changed = true;
        }
      }
    });

    if (changed) {
      if (mounted) setState(() => _sessions = newSessions);
      StorageService.saveSessions(_sessions);
    }
  }

  void _checkTimerAlerts() {
    final now = DateTime.now();
    _sessions.forEach((id, session) {
      if (session.isCoupure) return;
      
      final diff = session.endAt.difference(now);
      final secondsLeft = diff.inSeconds;

      // Déclenchement dès qu'on passe sous les 5 minutes (300 secondes)
      if (secondsLeft <= 300 && secondsLeft > 0) {
        if (!_alertedSessions.contains(id)) {
          _playCashSound();
          _alertedSessions.add(id);
          if (mounted) AppNotifications.show(context, 'Attention', 'Il reste 5 min sur ${session.posteNom}');
        }
      }
      
      // Réinitialisation de l'alerte si on rajoute du temps (plus de 5 min)
      if (secondsLeft > 300 && _alertedSessions.contains(id)) {
        _alertedSessions.remove(id);
      }
      
      // Nettoyage quand la session est terminée ou supprimée
      if (secondsLeft <= 0 && _alertedSessions.contains(id)) {
        _alertedSessions.remove(id);
      }
    });
  }

  Future<void> _playCashSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/cowbell.mp3'));
    } catch (e) {
      debugPrint("Erreur son: $e");
    }
  }

  Future<void> _reprendreSession(Poste p) async {
    bool success = await HardwareService.resumeAfterCoupure(p.nom.replaceAll('POSTE ', 'P'));
    if (success && mounted) {
      _syncWithHardware();
      AppNotifications.show(context, 'Succès', 'Session reprise sur ${p.nom}');
    }
  }

  void _showCoupureDialog(Poste p) {
    final s = _sessions[p.id];
    if (s == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.bolt, color: Colors.orange),
          const SizedBox(width: 10),
          Text('REPRISE ${p.nom}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Text('Le courant est revenu. Le joueur est-il présent pour terminer ses ${_formatTimeLeft(s.endAt, true)} ?',
          style: const TextStyle(color: AppColors.textSoft, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await HardwareService.sendDeactivation(p.nom.replaceAll('POSTE ', 'P'));
              _syncWithHardware();
            },
            child: const Text('NON (LIBÉRER)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reprendreSession(p);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
            child: const Text('OUI (REPRENDRE)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _demarrerSession() async {
    if (_wifiName != "WGM") return;
    if (_selectedPoste == null || _selectedTarif == null) return;

    final poste = _selectedPoste!;
    final tarif = _selectedTarif!;

    bool hwSuccess = await HardwareService.sendActivation(
      poste.nom.replaceAll('POSTE ', 'P'), 
      tarif.duree
    );

    if (!hwSuccess) return;

    final now = DateTime.now();
    
    // Log de sécurité immédiat
    await AuditService.logAction('DÉMARRAGE: ${poste.nom} - ${tarif.label} (${tarif.prix} CFA)');

    DateTime startAt = _sessions.containsKey(poste.id) ? _sessions[poste.id]!.endAt : now;
    final endAt = startAt.add(Duration(minutes: tarif.duree));
    
    final newSession = Session(
      posteId: poste.id,
      posteNom: poste.nom,
      endAt: endAt,
      totalDuree: (_sessions[poste.id]?.totalDuree ?? 0) + tarif.duree,
      totalPrix: (_sessions[poste.id]?.totalPrix ?? 0) + tarif.prix,
      lastTarifLabel: tarif.label,
    );

    if (mounted) setState(() => _selectedTarif = null);

    await StorageService.saveSessions({..._sessions, poste.id: newSession});
    
    final r = Recette(
      id: 'r-${DateTime.now().millisecondsSinceEpoch}', 
      posteId: poste.id, 
      posteNom: poste.nom, 
      duree: tarif.duree, 
      prix: tarif.prix, 
      createdAt: now,
      tarifLabel: tarif.label, // Ajout pour le PDF
    );

    await StorageService.addRecette(r);
    
    // Mise à jour du PDF instantanée
    final allRecettes = await StorageService.getRecettes();
    await AuditService.updateDailyReport(allRecettes);
    
    if (mounted) AppNotifications.show(context, 'Succès', 'Session activée et Archivée');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: TabBarView(controller: _tabController, children: [
            _buildPilotageTab(),
            _buildHistoriqueTab(),
          ])),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    bool isCorrectWifi = _wifiName == "WGM";
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: AppStyles.glass(opacity: 0.6, radius: 20),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Logo_Final.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.videogame_asset, color: AppColors.accent, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'WINNER GAME MANAGER',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCorrectWifi ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isCorrectWifi ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isCorrectWifi ? Icons.wifi : Icons.wifi_off, color: isCorrectWifi ? Colors.green : Colors.red, size: 14),
            const SizedBox(width: 6),
            Text(_wifiName ?? "Recherche...", style: TextStyle(color: isCorrectWifi ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 3,
          child: Center(
            child: SizedBox(
              height: 35,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.accent, width: 2)),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                tabs: const [
                  Tab(text: 'PILOTAGE'), 
                  Tab(text: 'RECETTES'),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())), 
          icon: const Icon(Icons.settings, size: 18, color: AppColors.textSoft)
        ),
      ]),
    );
  }

  Widget _buildPilotageTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: isMobile 
            ? SingleChildScrollView(
                child: Column(children: [
                  _buildInfoCard(),
                  const SizedBox(height: 12),
                  _buildActionCard(),
                  const SizedBox(height: 20),
                  const Align(alignment: Alignment.centerLeft, child: Text('VUE D\'ENSEMBLE', style: TextStyle(color: AppColors.textSoft, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  _buildPostesGrid(crossAxisCount: constraints.maxWidth < 600 ? 3 : 4, shrink: true),
                  const SizedBox(height: 20),
                ]),
              )
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 220, child: Column(children: [_buildInfoCard(), const SizedBox(height: 12), _buildActionCard()])),
                const SizedBox(width: 15),
                Expanded(child: _buildPostesGrid(crossAxisCount: 5)),
              ]),
        );
      }
    );
  }

  Widget _buildInfoCard() {
    final s = _selectedPoste != null ? _sessions[_selectedPoste!.id] : null;
    final isCoupure = s?.isCoupure ?? false;
    return Container(
      padding: const EdgeInsets.all(18), decoration: AppStyles.glass(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SÉLECTION', style: TextStyle(color: AppColors.accent, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_selectedPoste?.nom ?? 'AUCUN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(height: 25, color: Colors.white10),
        _row('Restant', s != null ? _formatTimeLeft(s.endAt, isCoupure) : '--:--', isBold: true),
        if (isCoupure) 
           const Padding(
             padding: EdgeInsets.only(top: 8),
             child: Text('EN ATTENTE REPRISE', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
           ),
        if (!isCoupure) _row('Fin', s != null ? DateFormat('HH:mm').format(s.endAt) : '--:--'),
      ]),
    );
  }

  Widget _row(String l, String v, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2), 
    child: Row(children: [
      Expanded(child: Text(l, style: const TextStyle(color: AppColors.textSoft, fontSize: 12), overflow: TextOverflow.ellipsis)), 
      const SizedBox(width: 5),
      Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? AppColors.accent : Colors.white, fontSize: isBold ? 16 : 13))
    ])
  );

  Widget _buildActionCard() {
    bool isCorrectWifi = _wifiName == "WGM";
    final s = _selectedPoste != null ? _sessions[_selectedPoste!.id] : null;
    final isCoupure = s?.isCoupure ?? false;
    final availableTarifs = _selectedPoste?.tarifs ?? [];
    
    return Container(
      padding: const EdgeInsets.all(18), decoration: AppStyles.glass(),
      child: Column(children: [
        if (isCoupure) ...[
          const Icon(Icons.history_toggle_off, color: Colors.orange, size: 30),
          const SizedBox(height: 10),
          const Text('SESSION SUSPENDUE', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 5),
          const Text('Cliquez sur l\'icône du poste pour valider la reprise.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSoft, fontSize: 10)),
        ] else ...[
          DropdownButtonFormField<Tarif>(
            initialValue: _selectedTarif, dropdownColor: AppColors.bgPanel,
            style: const TextStyle(fontSize: 13, color: Colors.white),
            items: availableTarifs.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
            onChanged: (v) => setState(() => _selectedTarif = v),
            decoration: const InputDecoration(labelText: 'FORFAIT', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity, 
            height: 45, 
            child: ElevatedButton(
              onPressed: isCorrectWifi ? _demarrerSession : null, 
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrectWifi ? AppColors.accent : Colors.grey.withValues(alpha: 0.1),
                foregroundColor: isCorrectWifi ? Colors.black : AppColors.textSoft,
              ),
              child: Text(isCorrectWifi ? 'DÉMARRER' : 'REQUIS: WIFI WGM', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
            )
          ),
        ],
      ]),
    );
  }

  Widget _buildPostesGrid({int crossAxisCount = 5, bool shrink = false}) {
    return GridView.builder(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.75),
      itemCount: _postes.length,
      itemBuilder: (context, i) => _buildPosteItem(i),
    );
  }

  Widget _buildPosteItem(int i) {
    final p = _postes[i];
    final session = _sessions[p.id];
    final active = session != null;
    final selected = _selectedPoste?.id == p.id;
    final isCoupure = session?.isCoupure ?? false;

    String imageAsset = 'assets/images/tv_off.png';
    if (isCoupure) {
      imageAsset = 'assets/images/tv_coupure.png';
    } else if (active) {
      imageAsset = 'assets/images/tv_on.png';
    }

    return InkWell(
      onTap: () {
        setState(() { _selectedPoste = p; _selectedTarif = null; });
        if (isCoupure) {
          _showCoupureDialog(p);
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.12) : (active ? (isCoupure ? Colors.orange.withValues(alpha: 0.1) : AppColors.bgPanel.withValues(alpha: 0.8)) : Colors.black.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? AppColors.accent : (active ? (isCoupure ? Colors.orange.withValues(alpha: 0.4) : AppColors.accent.withValues(alpha: 0.4)) : Colors.white.withValues(alpha: 0.05)), width: selected ? 1.5 : 1.0),
          boxShadow: selected ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 0)] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: active ? 1.0 : 0.4, child: Image.asset(imageAsset, fit: BoxFit.contain)),
                  if (active) Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: isCoupure ? Colors.orange : AppColors.accent, shape: BoxShape.circle, border: Border.all(color: AppColors.bgBase, width: 1.5)))),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              p.nom.replaceAll('POSTE ', 'P'), 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: active ? Colors.white : AppColors.textSoft), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoriqueTab() {
    final filtered = _recettes.where((r) => r.createdAt.day == _selectedDate.day && r.createdAt.month == _selectedDate.month && r.createdAt.year == _selectedDate.year).toList();
    Map<String, int> grouped = {};
    for (var r in filtered) { grouped[r.posteNom] = (grouped[r.posteNom] ?? 0) + r.prix; }
    final totalGlobal = filtered.fold(0, (sum, r) => sum + r.prix);
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(15), decoration: AppStyles.glass(),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton.icon(
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2023), lastDate: DateTime.now());
                if (d != null) setState(() => _selectedDate = d);
              },
              icon: const Icon(Icons.calendar_month, color: AppColors.accent, size: 18),
              label: Text(DateFormat('dd MMM yyyy').format(_selectedDate).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            Text('$totalGlobal CFA', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(child: ListView(children: grouped.entries.map((e) => ListTile(title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), trailing: Text('${e.value} CFA', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)))).toList())),
      ]),
    );
  }

  String _formatTimeLeft(DateTime endAt, [bool isPaused = false]) {
    final now = DateTime.now();
    final diff = endAt.difference(now);
    
    if (diff.isNegative) return "00:00";
    
    int totalSeconds = diff.inSeconds;
    
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
