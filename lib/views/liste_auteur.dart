import 'package:flutter/material.dart';
import 'package:tp_flutter2/views/edition_auteur.dart';

class ListeAuteur extends StatefulWidget {
  const ListeAuteur({Key? key}) : super(key: key);

  @override
  State<ListeAuteur> createState() => _ListeAuteurState();
}

class _ListeAuteurState extends State<ListeAuteur> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Liste des auteurs")),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditionAuteur()),
        );
      },
    ),
    body: ListView.builder(
      itemCount: 20,
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(Icons.book),
        title: Text("Titre du livre $i"),
        subtitle: Text("description du livre $i ..."),
        onTap: () {},
      ),
    ),
  );
}
