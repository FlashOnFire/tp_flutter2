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
      }
    } catch (e) {
      print('[SYNC] Authentication error: $e');
    }
  }

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncAll(isAutoSync: true);
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  Future<SyncResult> syncAll({bool isAutoSync = false}) async {
    try {
      final testResponse = await http.get(
        Uri.parse('$baseUrl/categories'),
      ).timeout(const Duration(seconds: 5));

      if (testResponse.statusCode != 200) {
        final result = SyncResult(success: false, error: 'Server not reachable');
        onSyncComplete?.call(result, isAutoSync);
        return result;
      }

      final lastSync = await getLastSyncTime();

      final categoriesResult = await syncCategories(lastSync);
      final auteursResult = await syncAuteurs(lastSync);
      final livresResult = await syncLivres(lastSync);

      await saveLastSyncTime(DateTime.now());

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
    } catch (e) {
      final result = SyncResult(success: false, error: e.toString());
      onSyncComplete?.call(result, isAutoSync);
      return result;
    }
  }

  DateTime _parseTimestamp(String timestamp) {
    return DateTime.parse(timestamp.replaceAll(' ', 'T'));
  }

  Future<EntitySyncResult> syncCategories(DateTime? lastSync) async {
    int uploaded = 0;
    int downloaded = 0;
    Set<int> uploadedIds = {};

    try {
      String whereClause = lastSync != null ? 'updated_at > ?' : '1=1';
      List<dynamic> whereArgs = lastSync != null ? [lastSync.toIso8601String()] : [];

      final localCategories = await database.query(
        'categorie',
        where: whereClause,
        whereArgs: whereArgs,
      );

      for (var cat in localCategories) {
        if (_jwtToken == null) continue;

        try {
          final updateResponse = await http.put(
            Uri.parse('$baseUrl/categories/${cat['id']}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_jwtToken',
            },
            body: jsonEncode({
              'libelle': cat['libelle'],
              'is_deleted': cat['is_deleted'] == 1,
              'updated_at': cat['updated_at'],
            }),
          );

          if (updateResponse.statusCode == 200) {
            uploaded++;
            uploadedIds.add(cat['id'] as int);
          } else {
            final createResponse = await http.post(
              Uri.parse('$baseUrl/categories'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_jwtToken',
              },
              body: jsonEncode({
                'libelle': cat['libelle'],
                'is_deleted': cat['is_deleted'] == 1,
                'updated_at': cat['updated_at'],
              }),
            );

            if (createResponse.statusCode == 201) {
              uploaded++;
              uploadedIds.add(cat['id'] as int);
            }
          }
        } catch (e) {
          print('[SYNC-CAT] Error uploading category: $e');
        }
      }

      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        final List<dynamic> serverCategories = jsonDecode(response.body);

        for (var serverCat in serverCategories) {
          if (uploadedIds.contains(serverCat['id'] as int)) continue;

          final serverUpdatedAt = _parseTimestamp(serverCat['updated_at'] as String);

          if (lastSync == null || serverUpdatedAt.isAfter(lastSync)) {
            final existing = await database.query(
              'categorie',
              where: 'id = ?',
              whereArgs: [serverCat['id']],
            );

            if (existing.isEmpty) {
              await database.insert('categorie', {
                'id': serverCat['id'],
                'libelle': serverCat['libelle'],
                'is_deleted': serverCat['is_deleted'] ?? 0,
                'updated_at': serverCat['updated_at'],
              });
              downloaded++;
            } else {
              final localUpdatedAt = _parseTimestamp(existing.first['updated_at'] as String);

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                await database.update(
                  'categorie',
                  {
                    'libelle': serverCat['libelle'],
                    'is_deleted': serverCat['is_deleted'] ?? 0,
                    'updated_at': serverCat['updated_at'],
                  },
                  where: 'id = ?',
                  whereArgs: [serverCat['id']],
                );
                downloaded++;
              }
            }
          }
        }
      }
    } catch (e) {
      print('[SYNC-CAT] Error: $e');
    }

    return EntitySyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  Future<EntitySyncResult> syncAuteurs(DateTime? lastSync) async {
    int uploaded = 0;
    int downloaded = 0;
    Set<int> uploadedIds = {};

    try {
      String whereClause = lastSync != null ? 'updated_at > ?' : '1=1';
      List<dynamic> whereArgs = lastSync != null ? [lastSync.toIso8601String()] : [];

      final localAuteurs = await database.query(
        'auteur',
        where: whereClause,
        whereArgs: whereArgs,
      );

      for (var auteur in localAuteurs) {
        if (_jwtToken == null) continue;

        try {
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
              'is_deleted': auteur['is_deleted'] == 1,
              'updated_at': auteur['updated_at'],
            }),
          );

          if (updateResponse.statusCode == 200) {
            uploaded++;
            uploadedIds.add(auteur['id'] as int);
          } else {
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
                'is_deleted': auteur['is_deleted'] == 1,
                'updated_at': auteur['updated_at'],
              }),
            );

            if (createResponse.statusCode == 201) {
              uploaded++;
              uploadedIds.add(auteur['id'] as int);
            }
          }
        } catch (e) {
          print('[SYNC-AUT] Error uploading auteur: $e');
        }
      }

      final response = await http.get(Uri.parse('$baseUrl/auteurs'));

      if (response.statusCode == 200) {
        final List<dynamic> serverAuteurs = jsonDecode(response.body);

        for (var serverAuteur in serverAuteurs) {
          if (uploadedIds.contains(serverAuteur['id'] as int)) continue;

          final serverUpdatedAt = _parseTimestamp(serverAuteur['updated_at'] as String);

          if (lastSync == null || serverUpdatedAt.isAfter(lastSync)) {
            final existing = await database.query(
              'auteur',
              where: 'id = ?',
              whereArgs: [serverAuteur['id']],
            );

            if (existing.isEmpty) {
              await database.insert('auteur', {
                'id': serverAuteur['id'],
                'nom': serverAuteur['nom'],
                'prenoms': serverAuteur['prenom'],
                'email': serverAuteur['mail'],
                'is_deleted': serverAuteur['is_deleted'] ?? 0,
                'updated_at': serverAuteur['updated_at'],
              });
              downloaded++;
            } else {
              final localUpdatedAt = _parseTimestamp(existing.first['updated_at'] as String);

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                await database.update(
                  'auteur',
                  {
                    'nom': serverAuteur['nom'],
                    'prenoms': serverAuteur['prenom'],
                    'email': serverAuteur['mail'],
                    'is_deleted': serverAuteur['is_deleted'] ?? 0,
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
      print('[SYNC-AUT] Error: $e');
    }

    return EntitySyncResult(uploaded: uploaded, downloaded: downloaded);
  }

  Future<EntitySyncResult> syncLivres(DateTime? lastSync) async {
    int uploaded = 0;
    int downloaded = 0;
    Set<int> uploadedIds = {};

    try {
      String whereClause = lastSync != null ? 'updated_at > ?' : '1=1';
      List<dynamic> whereArgs = lastSync != null ? [lastSync.toIso8601String()] : [];

      final localLivres = await database.query(
        'livre',
        where: whereClause,
        whereArgs: whereArgs,
      );

      for (var livre in localLivres) {
        if (_jwtToken == null) continue;

        try {
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
              'is_deleted': livre['is_deleted'] == 1,
              'updated_at': livre['updated_at'],
            }),
          );

          if (updateResponse.statusCode == 200) {
            uploaded++;
            uploadedIds.add(livre['id'] as int);
          } else {
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
                'is_deleted': livre['is_deleted'] == 1,
                'updated_at': livre['updated_at'],
              }),
            );

            if (createResponse.statusCode == 201) {
              uploaded++;
              uploadedIds.add(livre['id'] as int);
            }
          }
        } catch (e) {
          print('[SYNC-LIV] Error uploading livre: $e');
        }
      }

      final response = await http.get(Uri.parse('$baseUrl/livres'));

      if (response.statusCode == 200) {
        final List<dynamic> serverLivres = jsonDecode(response.body);

        for (var serverLivre in serverLivres) {
          if (uploadedIds.contains(serverLivre['id'] as int)) continue;

          final serverUpdatedAt = _parseTimestamp(serverLivre['updated_at'] as String);

          if (lastSync == null || serverUpdatedAt.isAfter(lastSync)) {
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
                'is_deleted': serverLivre['is_deleted'] ?? 0,
                'updated_at': serverLivre['updated_at'],
              });
              downloaded++;
            } else {
              final localUpdatedAt = _parseTimestamp(existing.first['updated_at'] as String);

              if (serverUpdatedAt.isAfter(localUpdatedAt)) {
                await database.update(
                  'livre',
                  {
                    'libelle': serverLivre['libelle'],
                    'description': serverLivre['description'],
                    'auteur_id': serverLivre['auteur_id'],
                    'categorie_id': serverLivre['categorie_id'],
                    'is_deleted': serverLivre['is_deleted'] ?? 0,
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
      print('[SYNC-LIV] Error: $e');
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
