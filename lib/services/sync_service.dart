import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SyncService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String lastSyncKey = 'last_sync_timestamp';

  final Database database;
  String? _jwtToken;
  Timer? _syncTimer;

  SyncService(this.database);

  void setToken(String token) {
    _jwtToken = token;
  }

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncAll();
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  Future<DateTime?> getLastSyncTime() async {
    final result = await database.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [lastSyncKey],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DateTime.parse(result.first['value'] as String);
  }

  Future<void> saveLastSyncTime(DateTime time) async {
    await database.insert(
      'sync_metadata',
      {'key': lastSyncKey, 'value': time.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SyncResult> syncAll() async {
    try {
      print('[SYNC] Starting synchronization...');
      print('[SYNC] Base URL: $baseUrl');

      try {
        print('[SYNC] Testing server connectivity...');
        final testResponse = await http.get(
          Uri.parse('$baseUrl/categories'),
        ).timeout(const Duration(seconds: 5));
        print('[SYNC] Server responded with status: ${testResponse.statusCode}');
      } catch (e) {
        print('[SYNC] ERROR: Server connectivity test FAILED: $e');
        print('[SYNC] ERROR: Make sure API server is running at $baseUrl');
        return SyncResult(success: false, error: 'Server not reachable: $e');
      }

      print('[SYNC] Syncing categories...');
      final categoriesResult = await syncCategories();
      print('[SYNC] SUCCESS: Categories: ${categoriesResult.uploaded} uploaded, ${categoriesResult.downloaded} downloaded');

      print('[SYNC] Syncing auteurs...');
      final auteursResult = await syncAuteurs();
      print('[SYNC] SUCCESS: Auteurs: ${auteursResult.uploaded} uploaded, ${auteursResult.downloaded} downloaded');

      print('[SYNC] Syncing livres...');
      final livresResult = await syncLivres();
      print('[SYNC] SUCCESS: Livres: ${livresResult.uploaded} uploaded, ${livresResult.downloaded} downloaded');

      await saveLastSyncTime(DateTime.now());

      print('[SYNC] SUCCESS: Synchronization completed successfully!');

      return SyncResult(
        success: true,
        categoriesUploaded: categoriesResult.uploaded,
        categoriesDownloaded: categoriesResult.downloaded,
        auteursUploaded: auteursResult.uploaded,
        auteursDownloaded: auteursResult.downloaded,
        livresUploaded: livresResult.uploaded,
        livresDownloaded: livresResult.downloaded,
      );
    } catch (e, stackTrace) {
      print('[SYNC] ERROR: Fatal error during sync: $e');
      print('[SYNC] ERROR: Stack trace: $stackTrace');
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<EntitySyncResult> syncCategories() async {
    int uploaded = 0;
    int downloaded = 0;

    try {
      final localCategories = await database.query('categorie');
      print('[SYNC-CAT] Found ${localCategories.length} local categories');

      for (var cat in localCategories) {
        if (cat['id'] == null || (cat['id'] as int) < 0) {
          print('[SYNC-CAT] Uploading category: ${cat['libelle']} (local ID: ${cat['id']})');
          try {
            final response = await http.post(
              Uri.parse('$baseUrl/categories'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'libelle': cat['libelle'],
                'created_at': cat['created_at'],
              }),
            );

            if (response.statusCode == 201) {
              final serverData = jsonDecode(response.body);
              print('[SYNC-CAT] SUCCESS: Category uploaded successfully, server ID: ${serverData['id']}');
              await database.update(
                'categorie',
                {'id': serverData['id']},
                where: 'id = ?',
                whereArgs: [cat['id']],
              );
              uploaded++;
            } else {
              print('[SYNC-CAT] WARNING: Upload failed with status: ${response.statusCode}');
            }
          } catch (e) {
            print('[SYNC-CAT] ERROR: Error uploading category: $e');
          }
        }
      }

      print('[SYNC-CAT] Downloading categories from server...');
      try {
        final response = await http.get(Uri.parse('$baseUrl/categories'));
        print('[SYNC-CAT] Server response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final List<dynamic> serverCategories = jsonDecode(response.body);
          print('[SYNC-CAT] Received ${serverCategories.length} categories from server');

          for (var serverCat in serverCategories) {
            final existing = await database.query(
              'categorie',
              where: 'id = ?',
              whereArgs: [serverCat['id']],
            );

            if (existing.isEmpty) {
              print('[SYNC-CAT] New category from server: ${serverCat['libelle']} (ID: ${serverCat['id']})');
              await database.insert('categorie', {
                'id': serverCat['id'],
                'libelle': serverCat['libelle'],
                'created_at': serverCat['created_at'],
              });
              downloaded++;
            } else {
              final localCreatedAt = DateTime.parse(existing.first['created_at'] as String);
              final serverCreatedAt = DateTime.parse(serverCat['created_at']);

              if (serverCreatedAt.isAfter(localCreatedAt)) {
                print('[SYNC-CAT] Updating category ${serverCat['libelle']} (server is newer)');
                await database.update(
                  'categorie',
                  {
                    'libelle': serverCat['libelle'],
                    'created_at': serverCat['created_at'],
                  },
                  where: 'id = ?',
                  whereArgs: [serverCat['id']],
                );
              }
            }
          }
        }
      } catch (e) {
        print('[SYNC-CAT] ERROR: Error downloading categories: $e');
      }
    } catch (e) {
      print('[SYNC-CAT] ERROR: Fatal error in syncCategories: $e');
    }

    return EntitySyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  Future<EntitySyncResult> syncAuteurs() async {
    int uploaded = 0;
    int downloaded = 0;

    final localAuteurs = await database.query('auteur');

    for (var auteur in localAuteurs) {
      if (auteur['id'] == null || (auteur['id'] as int) < 0) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/auteurs'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nom': auteur['nom'],
              'prenom': auteur['prenom'],
              'mail': auteur['mail'],
              'created_at': auteur['created_at'],
            }),
          );

          if (response.statusCode == 201) {
            final serverData = jsonDecode(response.body);
            await database.update(
              'auteur',
              {'id': serverData['id']},
              where: 'id = ?',
              whereArgs: [auteur['id']],
            );
            uploaded++;
          }
        } catch (e) {
          print('Error uploading auteur: $e');
        }
      }
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/auteurs'));

      if (response.statusCode == 200) {
        final List<dynamic> serverAuteurs = jsonDecode(response.body);

        for (var serverAuteur in serverAuteurs) {
          final existing = await database.query(
            'auteur',
            where: 'id = ?',
            whereArgs: [serverAuteur['id']],
          );

          if (existing.isEmpty) {
            await database.insert('auteur', {
              'id': serverAuteur['id'],
              'nom': serverAuteur['nom'],
              'prenom': serverAuteur['prenom'],
              'mail': serverAuteur['mail'],
              'created_at': serverAuteur['created_at'],
            });
            downloaded++;
          } else {
            final localCreatedAt = DateTime.parse(existing.first['created_at'] as String);
            final serverCreatedAt = DateTime.parse(serverAuteur['created_at']);

            if (serverCreatedAt.isAfter(localCreatedAt)) {
              await database.update(
                'auteur',
                {
                  'nom': serverAuteur['nom'],
                  'prenom': serverAuteur['prenom'],
                  'mail': serverAuteur['mail'],
                  'created_at': serverAuteur['created_at'],
                },
                where: 'id = ?',
                whereArgs: [serverAuteur['id']],
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error downloading auteurs: $e');
    }

    return EntitySyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  Future<EntitySyncResult> syncLivres() async {
    int uploaded = 0;
    int downloaded = 0;

    final localLivres = await database.query('livre');

    for (var livre in localLivres) {
      if (livre['id'] == null || (livre['id'] as int) < 0) {
        if (_jwtToken == null) {
          print('JWT token required for livre sync');
          continue;
        }

        try {
          final response = await http.post(
            Uri.parse('$baseUrl/livres'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_jwtToken',
            },
            body: jsonEncode({
              'libelle': livre['libelle'],
              'description': livre['description'],
              'auteur_id': livre['auteur_id'],
              'categorie_id': livre['categorie_id'],
              'created_at': livre['created_at'],
            }),
          );

          if (response.statusCode == 201) {
            final serverData = jsonDecode(response.body);
            await database.update(
              'livre',
              {'id': serverData['id']},
              where: 'id = ?',
              whereArgs: [livre['id']],
            );
            uploaded++;
          }
        } catch (e) {
          print('Error uploading livre: $e');
        }
      }
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/livres'));

      if (response.statusCode == 200) {
        final List<dynamic> serverLivres = jsonDecode(response.body);

        for (var serverLivre in serverLivres) {
          final existing = await database.query(
            'livre',
            where: 'id = ?',
            whereArgs: [serverLivre['id']],
          );

          if (existing.isEmpty) {
            await database.insert('livre', {
              'id': serverLivre['id'],
              'libelle': serverLivre['libelle'],
              'description': serverLivre['description'],
              'auteur_id': serverLivre['auteur_id'],
              'categorie_id': serverLivre['categorie_id'],
              'created_at': serverLivre['created_at'],
            });
            downloaded++;
          } else {
            final localCreatedAt = DateTime.parse(existing.first['created_at'] as String);
            final serverCreatedAt = DateTime.parse(serverLivre['created_at']);

            if (serverCreatedAt.isAfter(localCreatedAt)) {
              await database.update(
                'livre',
                {
                  'libelle': serverLivre['libelle'],
                  'description': serverLivre['description'],
                  'auteur_id': serverLivre['auteur_id'],
                  'categorie_id': serverLivre['categorie_id'],
                  'created_at': serverLivre['created_at'],
                },
                where: 'id = ?',
                whereArgs: [serverLivre['id']],
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error downloading livres: $e');
    }

    return EntitySyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

class SyncResult {
  final bool success;
  final String? error;
  final int categoriesUploaded;
  final int categoriesDownloaded;
  final int auteursUploaded;
  final int auteursDownloaded;
  final int livresUploaded;
  final int livresDownloaded;

  SyncResult({
    required this.success,
    this.error,
    this.categoriesUploaded = 0,
    this.categoriesDownloaded = 0,
    this.auteursUploaded = 0,
    this.auteursDownloaded = 0,
    this.livresUploaded = 0,
    this.livresDownloaded = 0,
  });

  int get totalUploaded => categoriesUploaded + auteursUploaded + livresUploaded;
  int get totalDownloaded => categoriesDownloaded + auteursDownloaded + livresDownloaded;
}

class EntitySyncResult {
  final int uploaded;
  final int downloaded;

  EntitySyncResult({required this.uploaded, required this.downloaded});
}
