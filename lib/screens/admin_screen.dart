import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../services/hardware_service.dart';
import '../widgets/notifications.dart';

import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Poste> _postes = [];

  final _posteNumberController = TextEditingController();
  final _tarifDureeController = TextEditingController();
  final _tarifPrixController = TextEditingController();
  final _ipBoitierController = TextEditingController();

  Poste? _selectedPosteForTarif;
  Poste? _selectedPosteToUpdate;

  // Mise à jour Boîtier
  bool _isUpdating = false;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final postes = await StorageService.getPostes();
    _ipBoitierController.text = HardwareService.currentIp;
    setState(() {
      _postes = postes;
      if (_postes.isNotEmpty) {
        // Recalage de l'instance sélectionnée pour éviter l'erreur Dropdown
        if (_selectedPosteForTarif != null) {
          final found = _postes.where((p) => p.id == _selectedPosteForTarif!.id);
          _selectedPosteForTarif = found.isNotEmpty ? found.first : _postes.first;
        } else {
          _selectedPosteForTarif = _postes.first;
        }

        if (_selectedPosteToUpdate != null) {
          final found = _postes.where((p) => p.id == _selectedPosteToUpdate!.id);
          _selectedPosteToUpdate = found.isNotEmpty ? found.first : _postes.first;
        } else {
          _selectedPosteToUpdate = _postes.first;
        }
      } else {
        _selectedPosteForTarif = null;
        _selectedPosteToUpdate = null;
      }
    });
  }

  Future<bool> _confirmDelete(String title, String content) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgPanel,
        title: Text(title, style: const TextStyle(color: AppColors.danger, fontSize: 16)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER', style: TextStyle(color: AppColors.textSoft))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SUPPRIMER', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  void _addPoste() {
    if (_posteNumberController.text.trim().isEmpty) return;
    final name = "POSTE ${_posteNumberController.text.trim()}";
    if (_postes.any((p) => p.nom == name)) {
      AppNotifications.show(context, 'Erreur', 'Ce numéro de poste existe déjà.');
      return;
    }
    final newPoste = Poste(id: 'p-${DateTime.now().millisecondsSinceEpoch}', nom: name, tarifs: []);
    _postes.add(newPoste);
    StorageService.savePostes(_postes);
    _posteNumberController.clear();
    _loadData();
    AppNotifications.show(context, 'Succès', '$name ajouté.');
  }

  void _addTarif() {
    if (_selectedPosteForTarif == null || _tarifDureeController.text.isEmpty || _tarifPrixController.text.isEmpty) return;
    final tarif = Tarif(
      id: 't-${DateTime.now().millisecondsSinceEpoch}',
      duree: int.tryParse(_tarifDureeController.text) ?? 0,
      prix: int.tryParse(_tarifPrixController.text) ?? 0,
    );
    final index = _postes.indexWhere((p) => p.id == _selectedPosteForTarif!.id);
    if (index != -1) {
      _postes[index].tarifs.add(tarif);
      StorageService.savePostes(_postes);
      _tarifDureeController.clear();
      _tarifPrixController.clear();
      _loadData();
      AppNotifications.show(context, 'Succès', 'Tarif ajouté.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: TabBarView(controller: _tabController, children: [
            _buildCreationTab(), 
            _buildListTab(),
            _buildUpdateTab(), 
            _buildUpBoitierTab(),
          ])),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: AppStyles.glass(opacity: 0.6, radius: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.accent)),
          const SizedBox(width: 5),
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
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ESPACE ADMINISTRATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 14)),
            Text('CONFIGURATION SYSTÈME', style: TextStyle(color: AppColors.accent, fontSize: 8, letterSpacing: 2)),
          ]),
        ]),
        SizedBox(
          height: 35,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            dividerColor: Colors.transparent,
            indicator: UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.accent, width: 2)),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            tabs: const [
              Tab(text: 'POSTES'), 
              Tab(text: 'LISTE'),
              Tab(text: 'M.A.J'),
              Tab(text: 'UP-BOITIER'),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCreationTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanel(
                title: 'NOUVEAU POSTE',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('POSTE ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(child: TextField(
                      controller: _posteNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: 'N°'),
                    )),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _addPoste, child: const Text('CRÉER'))),
                ]),
              ),
              SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 20 : 0),
              _buildPanel(
                title: 'AJOUTER TARIF',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  DropdownButtonFormField<Poste>(
                    initialValue: _selectedPosteForTarif, dropdownColor: AppColors.bgPanel,
                    items: _postes.map((p) => DropdownMenuItem(value: p, child: Text(p.nom))).toList(),
                    onChanged: (v) => setState(() => _selectedPosteForTarif = v),
                    decoration: const InputDecoration(labelText: 'CHOISIR POSTE'),
                  ),
                  const SizedBox(height: 5),
                  TextField(controller: _tarifDureeController, decoration: const InputDecoration(labelText: 'DURÉE (MIN)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 5),
                  TextField(controller: _tarifPrixController, decoration: const InputDecoration(labelText: 'PRIX (CFA)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _addTarif, child: const Text('ENREGISTRER'))),
                ]),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPanel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(20), 
      decoration: AppStyles.glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildUpdateTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPanel(
                title: 'SUPPRIMER POSTE',
                child: ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: _postes.length,
                  itemBuilder: (context, i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(_postes[i].nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18), onPressed: () async {
                      if (await _confirmDelete('SUPPRIMER POSTE', 'Voulez-vous vraiment supprimer ${_postes[i].nom} et ses tarifs ?')) {
                        setState(() { _postes.removeAt(i); StorageService.savePostes(_postes); });
                      }
                    }),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 20 : 0),
              _buildPanel(
                title: 'SUPPRIMER TARIFS',
                child: Column(children: [
                  DropdownButtonFormField<Poste>(
                    initialValue: _selectedPosteToUpdate, dropdownColor: AppColors.bgPanel,
                    items: _postes.map((p) => DropdownMenuItem(value: p, child: Text(p.nom))).toList(),
                    onChanged: (v) => setState(() => _selectedPosteToUpdate = v),
                    decoration: const InputDecoration(labelText: 'FILTRER PAR POSTE'),
                  ),
                  const SizedBox(height: 15),
                  if (_selectedPosteToUpdate != null)
                    ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedPosteToUpdate!.tarifs.length,
                      itemBuilder: (context, i) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(_selectedPosteToUpdate!.tarifs[i].label, style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(icon: const Icon(Icons.close, color: AppColors.textSoft, size: 16), onPressed: () async {
                          if (await _confirmDelete('SUPPRIMER TARIF', 'Voulez-vous supprimer ce tarif ?')) {
                            setState(() { _selectedPosteToUpdate!.tarifs.removeAt(i); StorageService.savePostes(_postes); });
                          }
                        }),
                      ),
                    ),
                ]),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildListTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _postes.length,
      itemBuilder: (context, i) {
        final p = _postes[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nom, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: p.tarifs.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.bgPanel, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                child: Text(t.label, style: const TextStyle(fontSize: 10)),
              )).toList(),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin'],
      );

      if (result != null) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      debugPrint("Erreur FilePicker: $e");
    }
  }

  Future<void> _startUpdate() async {
    if (_selectedFile == null || _selectedFile!.path == null) return;
    
    setState(() => _isUpdating = true);

    try {
      final bytes = await File(_selectedFile!.path!).readAsBytes();
      bool success = await HardwareService.sendUpdate(bytes);
      
      if (success) {
        AppNotifications.show(context, 'Succès', 'Mise à jour terminée. Le boîtier redémarre.');
        setState(() => _selectedFile = null);
      } else {
        AppNotifications.show(context, 'Erreur', 'Échec de la mise à jour.');
      }
    } catch (e) {
      AppNotifications.show(context, 'Erreur', 'Fichier illisible ou erreur réseau.');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Widget _buildUpBoitierTab() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(30),
        decoration: AppStyles.glass(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.system_update, color: AppColors.accent, size: 50),
          const SizedBox(height: 20),
          const Text('MISE À JOUR BOÎTIER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          const Text('Sélectionnez un fichier firmware (.bin) pour mettre à jour le système autonome.', 
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSoft, fontSize: 12)),
          const SizedBox(height: 30),
          
          if (_selectedFile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.file_present, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(child: Text(_selectedFile!.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                IconButton(onPressed: () => setState(() => _selectedFile = null), icon: const Icon(Icons.close, size: 18, color: Colors.red)),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          if (_isUpdating) ...[
            const LinearProgressIndicator(color: AppColors.accent, backgroundColor: Colors.white10),
            const SizedBox(height: 10),
            const Text('Envoi du firmware en cours...', style: TextStyle(fontSize: 11, color: AppColors.accent)),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('CHOISIR LE FICHIER'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedFile != null ? _startUpdate : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                child: const Text('LANCER LA MISE À JOUR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
