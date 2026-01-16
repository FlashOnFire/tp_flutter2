import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tp_flutter2/models/auteur.dart';
import 'package:tp_flutter2/models/categorie.dart';
import 'package:tp_flutter2/models/livre.dart';

class Dao {
  //La reférence de notre base de données
  static Database? _database;

  //Un getter qui renvoie l'objet de base de donnée.
  //Si la base n'existe pas _initDB la créé
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bibliotheca.db');
    return _database!;
  }

  //_initDB initialise notre base de données.
  static Future<Database> _initDB(String filePath) async {
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, filePath);
    print('Database path: $path');
    //openDatabase ouvre notre base de données située à l'emplacement "path"
    //si la base n'existe pas openDatabase exécute _createDB
    return await databaseFactory.openDatabase(path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  //_createDB est la méthode qui s'occupe de la définition des tables de notre base de données
  //_createDB exécute les transactions de base de données qui pour créer les tables
  static Future _createDB(Database db, int version) async {
    print('Creating database tables...');
    await db.execute('''
 CREATE TABLE auteur (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 nom VARCHAR(255) NOT NULL,
 prenoms VARCHAR(255) NOT NULL,
 email VARCHAR(255)
 )
 ''');
    await db.execute('''
 CREATE TABLE categorie (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 libelle VARCHAR(255) NOT NULL
 )
 ''');
    await db.execute('''
 CREATE TABLE livre (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 libelle VARCHAR(255) NOT NULL,
 description TEXT,
 auteur_id INTEGER NOT NULL,
 categorie_id INTEGER NOT NULL
 )
 ''');
  }

  static Future<List<Categorie>> listeCategorie() async {
    final db = await database;
    final maps = await db.query("categorie", columns: ["*"]);
    if (maps.isNotEmpty) {
      return maps.map((e) => Categorie.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // static Future<int> updateCategorie(Categorie categorie) async {
  //   final db = await database;
  //   return db.update(
  //     "categorie",
  //     categorie.toJson().remove("id"),
  //     where: 'id = ?',
  //     whereArgs: [categorie.id],
  //   );
  // }

  static Future<int> updateCategorie(Categorie categorie) async {
    final db = await database;
    final values = Map<String, Object?>.from(categorie.toJson());
    values.remove('id');
    return db.update(
      "categorie",
      values,
      where: 'id = ?',
      whereArgs: [categorie.id],
    );
  }

  static Future<Categorie> createCategorie(Categorie categorie) async {
    final db = await database;
    final values = Map<String, Object?>.from(categorie.toJson());
    values.remove('id');
    final id = await db.insert("categorie", values);
    categorie.id = id;
    return categorie;
  }

  static Future<int> delete(int id) async {
    final db = await database;
    return await db.delete("categorie", where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Auteur methods ====================

  static Future<List<Auteur>> listeAuteur() async {
    final db = await database;
    final maps = await db.query("auteur", columns: ["*"]);
    if (maps.isNotEmpty) {
      return maps.map((e) => Auteur.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  static Future<Auteur> createAuteur(Auteur auteur) async {
    final db = await database;
    final values = Map<String, Object?>.from(auteur.toJson());
    values.remove('id');
    final id = await db.insert("auteur", values);
    auteur.id = id;
    return auteur;
  }

  static Future<int> updateAuteur(Auteur auteur) async {
    final db = await database;
    final values = Map<String, Object?>.from(auteur.toJson());
    values.remove('id');
    return db.update(
      "auteur",
      values,
      where: 'id = ?',
      whereArgs: [auteur.id],
    );
  }

  static Future<int> deleteAuteur(int id) async {
    final db = await database;
    return await db.delete("auteur", where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Livre methods ====================

  static Future<List<Livre>> listeLivre() async {
    final db = await database;
    final maps = await db.query("livre", columns: ["*"]);
    if (maps.isNotEmpty) {
      return maps.map((e) => Livre.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  static Future<Livre> createLivre(Livre livre) async {
    final db = await database;
    final values = Map<String, Object?>.from(livre.toJson());
    values.remove('id');
    final id = await db.insert("livre", values);
    livre.id = id;
    return livre;
  }

  static Future<int> updateLivre(Livre livre) async {
    final db = await database;
    final values = Map<String, Object?>.from(livre.toJson());
    values.remove('id');
    return db.update(
      "livre",
      values,
      where: 'id = ?',
      whereArgs: [livre.id],
    );
  }

  static Future<int> deleteLivre(int id) async {
    final db = await database;
    return await db.delete("livre", where: 'id = ?', whereArgs: [id]);
  }
}
