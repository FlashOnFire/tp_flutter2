import 'package:tp_flutter2/views/liste_auteur.dart';
import 'package:tp_flutter2/views/liste_categorie.dart';
import 'package:tp_flutter2/views/liste_livre.dart';
import 'package:flutter/material.dart';
import 'package:tp_flutter2/main.dart' show syncService;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSyncing = false;
  String _syncStatus = '';

  Future<void> _performSync() async {
    if (_isSyncing || syncService == null) {
      print('[UI] Sync already in progress or service not available');
      return;
    }

    print('[UI] User triggered manual sync');
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Synchronisation en cours...';
    });

    try {
      final result = await syncService!.syncAll();

      if (!mounted) return;

      final message = result.success
          ? 'Sync réussie: ${result.totalUploaded} envoyés, ${result.totalDownloaded} reçus'
          : 'Erreur de sync: ${result.error}';

      print('[UI] Sync result: $message');

      setState(() {
        _syncStatus = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('[UI] ERROR: Sync exception: $e');
      if (mounted) {
        setState(() {
          _syncStatus = 'Erreur: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        // Clear status after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _syncStatus = '';
            });
          }
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
          tooltip: 'Synchroniser avec le serveur',
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
            color: _syncStatus.contains('Erreur') ? Colors.red.shade100 : Colors.green.shade100,
            child: Text(
              _syncStatus,
              style: TextStyle(
                color: _syncStatus.contains('Erreur') ? Colors.red.shade900 : Colors.green.shade900,
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
