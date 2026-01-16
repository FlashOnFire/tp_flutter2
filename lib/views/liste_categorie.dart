import 'package:flutter/material.dart';
import 'package:tp_flutter2/views/edition_categorie.dart';

class ListeCategorie extends StatefulWidget {
  const ListeCategorie({Key? key}) : super(key: key);

  @override
  State<ListeCategorie> createState() => _ListeCategorieState();
}

class _ListeCategorieState extends State<ListeCategorie> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Liste des catégories")),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditionCategorie()),
        );
      },
    ),
    body: ListView.builder(
      itemCount: 20,
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(Icons.book),
        title: Text("Titre de la catégorie $i"),
        onTap: () {},
      ),
    ),
  );
}
