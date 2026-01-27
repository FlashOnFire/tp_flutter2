import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tp_flutter2/views/home_page.dart';
import 'package:tp_flutter2/models/database/dao.dart';
import 'package:tp_flutter2/services/sync_service.dart';

SyncService? syncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('[APP] Initializing Bibliotheca...');

  print('[APP] Initializing database...');
  final db = await Dao.database;

  print('[APP] Creating sync service...');
  syncService = SyncService(db);

  print('[APP] Authenticating to API...');
  await syncService!.authenticate();

  print('[APP] Starting automatic sync...');
  syncService!.startAutoSync();

  print('[APP] Performing initial sync...');
  syncService!.syncAll(isAutoSync: false).then((result) {
    if (result.success) {
      print('[APP] SUCCESS: Initial sync completed successfully');
    } else {
      print('[APP] ERROR: Initial sync failed: ${result.error}');
    }
  }).catchError((error) {
    print('[APP] ERROR: Initial sync error: $error');
  });

  print('[APP] Starting app...');
  runApp(
    MaterialApp(
      title: "Bibliotheca",
      theme: ThemeData(primaryColor: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    ),
  );
}

