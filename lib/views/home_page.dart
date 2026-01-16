import 'package:tp_flutter2/views/liste_auteur.dart';
import 'package:tp_flutter2/views/liste_categorie.dart';
import 'package:tp_flutter2/views/liste_livre.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Bienvenue sur Bibliotheca")),
    body: GridView(
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
  );
}
