import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

typedef SyncCallback = void Function(SyncResult result, bool isAutoSync);

class SyncService {
  static const String baseUrl = 'http://localhost:3000/api';

  final Database database;
  String? _jwtToken;
  Timer? _syncTimer;
  SyncCallback? onSyncComplete;

  SyncService(this.database);

  void setToken(String token) {
    _jwtToken = token;
  }

  Future<void> authenticate() async {
    try {
      print('[SYNC] Authenticating to get JWT token...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'admin@mail.com',
          'password': 'admin123',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        print('[SYNC] SUCCESS: JWT token obtained');
      } else {
        print('[SYNC] WARNING: Authentication failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('[SYNC] ERROR: Authentication error: $e');
    }
  }

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      print('[SYNC] Auto-sync triggered');
      syncAll(isAutoSync: true);
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  Future<SyncResult> syncAll({bool isAutoSync = false}) async {
    try {
      final syncType = isAutoSync ? 'AUTO-SYNC' : 'MANUAL-SYNC';
      print('[$syncType] Starting synchronization...');
      print('[$syncType] Base URL: $baseUrl');

      try {
        print('[$syncType] Testing server connectivity...');
        final testResponse = await http.get(
          Uri.parse('$baseUrl/categories'),
        ).timeout(const Duration(seconds: 5));
        print('[$syncType] Server responded with status: ${testResponse.statusCode}');
      } catch (e) {
        print('[$syncType] ERROR: Server connectivity test FAILED: $e');
        print('[$syncType] ERROR: Make sure API server is running at $baseUrl');
        final result = SyncResult(success: false, error: 'Server not reachable: $e');
        onSyncComplete?.call(result, isAutoSync);
        return result;
      }

      print('[$syncType] Syncing categories...');
      final categoriesResult = await syncCategories();
      print('[$syncType] SUCCESS: Categories: ${categoriesResult.uploaded} uploaded, ${categoriesResult.downloaded} downloaded');

      print('[$syncType] Syncing auteurs...');
      final auteursResult = await syncAuteurs();
      print('[$syncType] SUCCESS: Auteurs: ${auteursResult.uploaded} uploaded, ${auteursResult.downloaded} downloaded');

      print('[$syncType] Syncing livres...');
      final livresResult = await syncLivres();
      print('[$syncType] SUCCESS: Livres: ${livresResult.uploaded} uploaded, ${livresResult.downloaded} downloaded');

      print('[$syncType] SUCCESS: Synchronization completed successfully!');

      final result = SyncResult(
        success: true,
        categoriesUploaded: categoriesResult.uploaded,
        categoriesDownloaded: categoriesResult.downloaded,
        auteursUploaded: auteursResult.uploaded,
        auteursDownloaded: auteursResult.downloaded,
        livresUploaded: livresResult.uploaded,
        livresDownloaded: livresResult.downloaded,
      );

      onSyncComplete?.call(result, isAutoSync);
      return result;
    } catch (e, stackTrace) {
      final syncType = isAutoSync ? 'AUTO-SYNC' : 'MANUAL-SYNC';
      print('[$syncType] ERROR: Fatal error during sync: $e');
      print('[$syncType] ERROR: Stack trace: $stackTrace');
      final result = SyncResult(success: false, error: e.toString());
      onSyncComplete?.call(result, isAutoSync);
      return result;
    }
  }

  Future<EntitySyncResult> syncCategories() async {
    int uploaded = 0;
    int downloaded = 0;

    try {
      final localCategories = await database.query('categorie');
      print('[SYNC-CAT] Found ${localCategories.length} local categories');

      for (var cat in localCategories) {
        if (cat['id'] != null && (cat['id'] as int) < 0) {
          if (_jwtToken == null) {
            print('[SYNC-CAT] WARNING: JWT token required for category sync');
            continue;
          }

          print('[SYNC-CAT] Uploading category: ${cat['libelle']} (local ID: ${cat['id']})');
          try {
            final response = await http.post(
              Uri.parse('$baseUrl/categories'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_jwtToken',
              },
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
    print('[SYNC-AUT] Found ${localAuteurs.length} local auteurs');

    for (var auteur in localAuteurs) {
      if (auteur['id'] != null && (auteur['id'] as int) < 0) {
        if (_jwtToken == null) {
          print('[SYNC-AUT] WARNING: JWT token required for auteur sync');
          continue;
        }

        print('[SYNC-AUT] Uploading auteur: ${auteur['nom']} ${auteur['prenoms']} (local ID: ${auteur['id']})');
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/auteurs'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_jwtToken',
            },
            body: jsonEncode({
              'nom': auteur['nom'],
              'prenom': auteur['prenoms'],
              'mail': auteur['email'],
              'created_at': auteur['created_at'],
            }),
          );

          if (response.statusCode == 201) {
            final serverData = jsonDecode(response.body);
            print('[SYNC-AUT] SUCCESS: Auteur uploaded, server ID: ${serverData['id']}');
            await database.update(
              'auteur',
              {'id': serverData['id']},
              where: 'id = ?',
              whereArgs: [auteur['id']],
            );
            uploaded++;
          } else {
            print('[SYNC-AUT] WARNING: Upload failed with status: ${response.statusCode}');
          }
        } catch (e) {
          print('[SYNC-AUT] ERROR: Error uploading auteur: $e');
        }
      }
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/auteurs'));

      if (response.statusCode == 200) {
        final List<dynamic> serverAuteurs = jsonDecode(response.body);
        print('[SYNC-AUT] Received ${serverAuteurs.length} auteurs from server');

        for (var serverAuteur in serverAuteurs) {
          final existing = await database.query(
            'auteur',
            where: 'id = ?',
            whereArgs: [serverAuteur['id']],
          );

          if (existing.isEmpty) {
            print('[SYNC-AUT] New auteur from server: ${serverAuteur['nom']} (ID: ${serverAuteur['id']})');
            await database.insert('auteur', {
              'id': serverAuteur['id'],
              'nom': serverAuteur['nom'],
              'prenoms': serverAuteur['prenom'],
              'email': serverAuteur['mail'],
              'created_at': serverAuteur['created_at'],
            });
            downloaded++;
          } else {
            final localCreatedAt = DateTime.parse(existing.first['created_at'] as String);
            final serverCreatedAt = DateTime.parse(serverAuteur['created_at']);

            if (serverCreatedAt.isAfter(localCreatedAt)) {
              print('[SYNC-AUT] Updating auteur ${serverAuteur['nom']} (server is newer)');
              await database.update(
                'auteur',
                {
                  'nom': serverAuteur['nom'],
                  'prenoms': serverAuteur['prenom'],
                  'email': serverAuteur['mail'],
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
      print('[SYNC-AUT] ERROR: Error downloading auteurs: $e');
    }

    return EntitySyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  Future<EntitySyncResult> syncLivres() async {
    int uploaded = 0;
    int downloaded = 0;

    final localLivres = await database.query('livre');
    print('[SYNC-LIV] Found ${localLivres.length} local livres');

    for (var livre in localLivres) {
      if (livre['id'] != null && (livre['id'] as int) < 0) {
        if (_jwtToken == null) {
          print('[SYNC-LIV] WARNING: JWT token required for livre sync');
          continue;
        }

        final auteurId = livre['auteur_id'] as int;
        final categorieId = livre['categorie_id'] as int;

        if (auteurId < 0 || categorieId < 0) {
          print('[SYNC-LIV] SKIP: Cannot upload livre "${livre['libelle']}" - auteur (ID: $auteurId) or categorie (ID: $categorieId) not yet synced');
          continue;
        }

        print('[SYNC-LIV] Uploading livre: ${livre['libelle']} (local ID: ${livre['id']})');
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
              'auteur_id': auteurId,
              'categorie_id': categorieId,
              'created_at': livre['created_at'],
            }),
          );

          if (response.statusCode == 201) {
            final serverData = jsonDecode(response.body);
            print('[SYNC-LIV] SUCCESS: Livre uploaded, server ID: ${serverData['id']}');
            await database.update(
              'livre',
              {'id': serverData['id']},
              where: 'id = ?',
              whereArgs: [livre['id']],
            );
            uploaded++;
          } else {
            print('[SYNC-LIV] WARNING: Upload failed with status: ${response.statusCode}, body: ${response.body}');
          }
        } catch (e) {
          print('[SYNC-LIV] ERROR: Error uploading livre: $e');
        }
      }
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/livres'));

      if (response.statusCode == 200) {
        final List<dynamic> serverLivres = jsonDecode(response.body);
        print('[SYNC-LIV] Received ${serverLivres.length} livres from server');

        for (var serverLivre in serverLivres) {
          final existing = await database.query(
            'livre',
            where: 'id = ?',
            whereArgs: [serverLivre['id']],
          );

          if (existing.isEmpty) {
            print('[SYNC-LIV] New livre from server: ${serverLivre['libelle']} (ID: ${serverLivre['id']})');
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
              print('[SYNC-LIV] Updating livre ${serverLivre['libelle']} (server is newer)');
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
      print('[SYNC-LIV] ERROR: Error downloading livres: $e');
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
