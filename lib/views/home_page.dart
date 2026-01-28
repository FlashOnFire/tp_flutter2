import 'package:tp_flutter2/views/liste_auteur.dart';
import 'package:tp_flutter2/views/liste_categorie.dart';
import 'package:tp_flutter2/views/liste_livre.dart';
import 'package:flutter/material.dart';
import 'package:tp_flutter2/main.dart' show syncService;
import 'package:tp_flutter2/services/sync_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSyncing = false;
  String _syncStatus = '';

  @override
  void initState() {
    super.initState();
    if (syncService != null) {
      syncService!.onSyncComplete = _onSyncComplete;
    }
  }

  @override
  void dispose() {
    if (syncService != null) {
      syncService!.onSyncComplete = null;
    }
    super.dispose();
  }

  void _onSyncComplete(SyncResult result, bool isAutoSync) {
    if (!mounted) return;

    final syncType = isAutoSync ? 'AUTO-SYNC' : 'MANUAL-SYNC';
    final message = result.success
        ? 'Sync completed: ${result.totalUploaded} uploaded, ${result.totalDownloaded} downloaded'
        : 'Sync failed: ${result.error}';

    print('[UI] Sync completed - Type: $syncType, Success: ${result.success}, Message: $message');

    setState(() {
      _syncStatus = message;
      _isSyncing = false;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _syncStatus = '';
        });
      }
    });
  }

  Future<void> _performSync() async {
    if (_isSyncing || syncService == null) {
      print('[UI] Sync already in progress or service not available');
      return;
    }

    print('[UI] User triggered manual sync');
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Synchronizing...';
    });

    try {
      await syncService!.syncAll(isAutoSync: false);
    } catch (e) {
      print('[UI] ERROR: Sync exception: $e');
      if (mounted) {
        setState(() {
          _syncStatus = 'Error: $e';
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Bienvenue sur Bibliotheca"),
      actions: [
        IconButton(
          icon: _isSyncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.sync, size: 28),
          onPressed: _isSyncing ? null : _performSync,
          tooltip: 'Synchronize with server',
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            children: [
              MaterialButton(
                textColor: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListeLivrePage()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.book, size: 50),
                    SizedBox(height: 20),
                    Text("Livres", style: TextStyle(fontSize: 17)),
                  ],
                ),
              ),
              MaterialButton(
                textColor: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListeCategorie()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.category, size: 50),
                    SizedBox(height: 20),
                    Text("Catégories", style: TextStyle(fontSize: 17)),
                  ],
                ),
              ),
              MaterialButton(
                textColor: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListeAuteur()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person, size: 50),
                    SizedBox(height: 20),
                    Text("Auteur", style: TextStyle(fontSize: 17)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_syncStatus.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _syncStatus.contains('failed') || _syncStatus.contains('Error')
                ? Colors.red.shade100
                : Colors.green.shade100,
            child: Text(
              _syncStatus,
              style: TextStyle(
                color: _syncStatus.contains('failed') || _syncStatus.contains('Error')
                    ? Colors.red.shade900
                    : Colors.green.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ),
  );
}
