import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tp_flutter2/models/categorie.dart';
import 'package:tp_flutter2/models/database/dao.dart';
import 'package:tp_flutter2/views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  //Insertion
  var cat = Categorie(libelle: "dramatuge");
  cat = await Dao.createCategorie(cat);
  await affichage();
  //Mise à jour
  cat.libelle = "Poème";
  await Dao.updateCategorie(cat);
  await affichage();
  //Suppression
  await Dao.delete(cat.id!);
  await affichage();

  runApp(
    MaterialApp(
      title: "Bibliotheca",
      theme: ThemeData(primaryColor: Colors.blue),
      home: const HomePage(),
    ),
  );
}

Future affichage() async {
  //Lecture des données
  var cats = await Dao.listeCategorie();
  print(cats.map((e) => e.toJson()).toList());
}
