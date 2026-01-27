import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

typedef SyncCallback = void Function(SyncResult result, bool isAutoSync);

class SyncService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String lastSyncKey = 'last_sync_timestamp';

  final Database database;
  String? _jwtToken;
  Timer? _syncTimer;
  SyncCallback? onSyncComplete;

  SyncService(this.database);

  void setToken(String token) {
    _jwtToken = token;
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

      final lastSync = await getLastSyncTime();
      print('[$syncType] Last sync time: ${lastSync?.toIso8601String() ?? "Never"}');

      print('[$syncType] Syncing categories...');
      final categoriesResult = await syncCategories(lastSync);
      print('[$syncType] SUCCESS: Categories: ${categoriesResult.uploaded} uploaded, ${categoriesResult.downloaded} downloaded');

      print('[$syncType] Syncing auteurs...');
      final auteursResult = await syncAuteurs(lastSync);
      print('[$syncType] SUCCESS: Auteurs: ${auteursResult.uploaded} uploaded, ${auteursResult.downloaded} downloaded');

      print('[$syncType] Syncing livres...');
      final livresResult = await syncLivres(lastSync);
      print('[$syncType] SUCCESS: Livres: ${livresResult.uploaded} uploaded, ${livresResult.downloaded} downloaded');

      await saveLastSyncTime(DateTime.now());

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

  Future<EntitySyncResult> syncCategories(DateTime? lastSync) async {
    int uploaded = 0;
    int downloaded = 0;

    try {
      // Upload local changes (categories updated since last sync)
      String whereClause = lastSync != null ? 'updated_at > ?' : '1=1';
      List<dynamic> whereArgs = lastSync != null ? [lastSync.toIso8601String()] : [];

      final localCategories = await database.query(
        'categorie',
        where: whereClause,
        whereArgs: whereArgs,
      );
      print('[SYNC-CAT] Found ${localCategories.length} local categories to upload');

      for (var cat in localCategories) {
        if (_jwtToken == null) {
          print('[SYNC-CAT] WARNING: JWT token required for category sync');
          continue;
        }

        print('[SYNC-CAT] Uploading/updating category: ${cat['libelle']} (ID: ${cat['id']})');
        try {
          // Try to update first (if it exists on server)
          final updateResponse = await http.put(
            Uri.parse('$baseUrl/categories/${cat['id']}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_jwtToken',
            },
            body: jsonEncode({
              'libelle': cat['libelle'],
              'updated_at': cat['updated_at'],
            }),
          );

          if (updateResponse.statusCode == 200) {
            print('[SYNC-CAT] SUCCESS: Category updated on server');
            uploaded++;
          } else {
            // If update fails, try to create
            final createResponse = await http.post(
              Uri.parse('$baseUrl/categories'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_jwtToken',
              },
              body: jsonEncode({
                'libelle': cat['libelle'],
                'updated_at': cat['updated_at'],
              }),
            );

            if (createResponse.statusCode == 201) {
              print('[SYNC-CAT] SUCCESS: Category created on server');
              uploaded++;
            } else {
              print('[SYNC-CAT] WARNING: Upload failed with status: ${createResponse.statusCode}');
            }
          }
        } catch (e) {
          print('[SYNC-CAT] ERROR: Error uploading category: $e');
        }
      }

      // Download server changes (categories updated since last sync)
      try {
        final response = await http.get(Uri.parse('$baseUrl/categories'));
        print('[SYNC-CAT] Server response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final List<dynamic> serverCategories = jsonDecode(response.body);
          print('[SYNC-CAT] Received ${serverCategories.length} categories from server');

          for (var serverCat in serverCategories) {
            // Convert MySQL datetime format to ISO format for parsing
            final updatedAtStr = (serverCat['updated_at'] as String).replaceAll(' ', 'T');
            final serverUpdatedAt = DateTime.parse(updatedAtStr);

            print('[SYNC-CAT] Processing category: ${serverCat['libelle']}, updated_at: ${serverCat['updated_at']}, lastSync: ${lastSync?.toIso8601String() ?? "null"}');

            // Only process if newer than last sync
            if (lastSync == null || serverUpdatedAt.isAfter(lastSync)) {
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
                  'updated_at': serverCat['updated_at'],
                });
                downloaded++;
              } else {
                final localUpdatedAtStr = (existing.first['updated_at'] as String).replaceAll(' ', 'T');
                final localUpdatedAt = DateTime.parse(localUpdatedAtStr);

                if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                  print('[SYNC-CAT] Updating category ${serverCat['libelle']} (server is newer)');
                  await database.update(
                    'categorie',
                    {
                      'libelle': serverCat['libelle'],
                      'updated_at': serverCat['updated_at'],
                    },
                    where: 'id = ?',
                    whereArgs: [serverCat['id']],
                  );
                  downloaded++;
                }
              }
            } else {
              print('[SYNC-CAT] SKIP: Category ${serverCat['libelle']} not newer than lastSync');
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

  Future<EntitySyncResult> syncAuteurs(DateTime? lastSync) async {
    int uploaded = 0;
    int downloaded = 0;

    try {
      // Upload local changes (auteurs updated since last sync)
      String whereClause = lastSync != null ? 'updated_at > ?' : '1=1';
      List<dynamic> whereArgs = lastSync != null ? [lastSync.toIso8601String()] : [];

      final localAuteurs = await database.query(
        'auteur',
        where: whereClause,
        whereArgs: whereArgs,
      );
      print('[SYNC-AUT] Found ${localAuteurs.length} local auteurs to upload');

      for (var auteur in localAuteurs) {
        if (_jwtToken == null) {
          print('[SYNC-AUT] WARNING: JWT token required for auteur sync');
          continue;
        }

        print('[SYNC-AUT] Uploading/updating auteur: ${auteur['nom']} ${auteur['prenoms']} (ID: ${auteur['id']})');
        try {
          // Try to update first
          final updateResponse = await http.put(
            Uri.parse('$baseUrl/auteurs/${auteur['id']}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_jwtToken',
            },
            body: jsonEncode({
              'nom': auteur['nom'],
              'prenom': auteur['prenoms'],
              'mail': auteur['email'],
              'updated_at': auteur['updated_at'],
            }),
          );

          if (updateResponse.statusCode == 200) {
            print('[SYNC-AUT] SUCCESS: Auteur updated on server');
            uploaded++;
          } else {
            // If update fails, try to create
            final createResponse = await http.post(
              Uri.parse('$baseUrl/auteurs'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_jwtToken',
              },
              body: jsonEncode({
                'nom': auteur['nom'],
                'prenom': auteur['prenoms'],
                'mail': auteur['email'],
                'updated_at': auteur['updated_at'],
              }),
            );

            if (createResponse.statusCode == 201) {
              print('[SYNC-AUT] SUCCESS: Auteur created on server');
              uploaded++;
            } else {
              print('[SYNC-AUT] WARNING: Upload failed with status: ${createResponse.statusCode}');
            }
          }
        } catch (e) {
          print('[SYNC-AUT] ERROR: Error uploading auteur: $e');
        }
      }

      // Download server changes
      try {
        final response = await http.get(Uri.parse('$baseUrl/auteurs'));

        if (response.statusCode == 200) {
          final List<dynamic> serverAuteurs = jsonDecode(response.body);
          print('[SYNC-AUT] Received ${serverAuteurs.length} auteurs from server');

          for (var serverAuteur in serverAuteurs) {
            // Convert MySQL datetime format to ISO format for parsing
            final updatedAtStr = (serverAuteur['updated_at'] as String).replaceAll(' ', 'T');
            final serverUpdatedAt = DateTime.parse(updatedAtStr);

            // Only process if newer than last sync
            if (lastSync == null || serverUpdatedAt.isAfter(lastSync)) {
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
                  'updated_at': serverAuteur['updated_at'],
                });
                downloaded++;
              } else {
                final localUpdatedAtStr = (existing.first['updated_at'] as String).replaceAll(' ', 'T');
                final localUpdatedAt = DateTime.parse(localUpdatedAtStr);

                if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                  print('[SYNC-AUT] Updating auteur ${serverAuteur['nom']} (server is newer)');
                  await database.update(
                    'auteur',
                    {
                      'nom': serverAuteur['nom'],
                      'prenoms': serverAuteur['prenom'],
                      'email': serverAuteur['mail'],
                      'updated_at': serverAuteur['updated_at'],
                    },
                    where: 'id = ?',
                    whereArgs: [serverAuteur['id']],
                  );
                  downloaded++;
                }
              }
            }
          }
        }
      } catch (e) {
        print('[SYNC-AUT] ERROR: Error downloading auteurs: $e');
      }
    } catch (e) {
      print('[SYNC-AUT] ERROR: Fatal error in syncAuteurs: $e');
    }

    return EntitySyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  Future<EntitySyncResult> syncLivres(DateTime? lastSync) async {
    int uploaded = 0;
    int downloaded = 0;

    try {
      // Upload local changes (livres updated since last sync)
      String whereClause = lastSync != null ? 'updated_at > ?' : '1=1';
      List<dynamic> whereArgs = lastSync != null ? [lastSync.toIso8601String()] : [];

      final localLivres = await database.query(
        'livre',
        where: whereClause,
        whereArgs: whereArgs,
      );
      print('[SYNC-LIV] Found ${localLivres.length} local livres to upload');

      for (var livre in localLivres) {
        if (_jwtToken == null) {
          print('[SYNC-LIV] WARNING: JWT token required for livre sync');
          continue;
        }

        print('[SYNC-LIV] Uploading/updating livre: ${livre['libelle']} (ID: ${livre['id']})');
        try {
          // Try to update first
          final updateResponse = await http.put(
            Uri.parse('$baseUrl/livres/${livre['id']}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_jwtToken',
            },
            body: jsonEncode({
              'libelle': livre['libelle'],
              'description': livre['description'],
              'auteur_id': livre['auteur_id'],
              'categorie_id': livre['categorie_id'],
              'updated_at': livre['updated_at'],
            }),
          );

          if (updateResponse.statusCode == 200) {
            print('[SYNC-LIV] SUCCESS: Livre updated on server');
            uploaded++;
          } else {
            // If update fails, try to create
            final createResponse = await http.post(
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
                'updated_at': livre['updated_at'],
              }),
            );

            if (createResponse.statusCode == 201) {
              print('[SYNC-LIV] SUCCESS: Livre created on server');
              uploaded++;
            } else {
              print('[SYNC-LIV] WARNING: Upload failed with status: ${createResponse.statusCode}, body: ${createResponse.body}');
            }
          }
        } catch (e) {
          print('[SYNC-LIV] ERROR: Error uploading livre: $e');
        }
      }

      // Download server changes
      try {
        final response = await http.get(Uri.parse('$baseUrl/livres'));

        if (response.statusCode == 200) {
          final List<dynamic> serverLivres = jsonDecode(response.body);
          print('[SYNC-LIV] Received ${serverLivres.length} livres from server');

          for (var serverLivre in serverLivres) {
            // Convert MySQL datetime format to ISO format for parsing
            final updatedAtStr = (serverLivre['updated_at'] as String).replaceAll(' ', 'T');
            final serverUpdatedAt = DateTime.parse(updatedAtStr);

            // Only process if newer than last sync
            if (lastSync == null || serverUpdatedAt.isAfter(lastSync)) {
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
                  'updated_at': serverLivre['updated_at'],
                });
                downloaded++;
              } else {
                final localUpdatedAtStr = (existing.first['updated_at'] as String).replaceAll(' ', 'T');
                final localUpdatedAt = DateTime.parse(localUpdatedAtStr);

                if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                  print('[SYNC-LIV] Updating livre ${serverLivre['libelle']} (server is newer)');
                  await database.update(
                    'livre',
                    {
                      'libelle': serverLivre['libelle'],
                      'description': serverLivre['description'],
                      'auteur_id': serverLivre['auteur_id'],
                      'categorie_id': serverLivre['categorie_id'],
                      'updated_at': serverLivre['updated_at'],
                    },
                    where: 'id = ?',
                    whereArgs: [serverLivre['id']],
                  );
                  downloaded++;
                }
              }
            }
          }
        }
      } catch (e) {
        print('[SYNC-LIV] ERROR: Error downloading livres: $e');
      }
    } catch (e) {
      print('[SYNC-LIV] ERROR: Fatal error in syncLivres: $e');
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
