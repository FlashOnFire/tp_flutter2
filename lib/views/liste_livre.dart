import 'package:flutter/material.dart';
import 'package:tp_flutter2/views/edition_livre.dart';

class ListeLivrePage extends StatefulWidget {
  const ListeLivrePage({Key? key}) : super(key: key);

  @override
  State<ListeLivrePage> createState() => _ListeLivrePageState();
}

class _ListeLivrePageState extends State<ListeLivrePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Liste des livres")),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditionLivre()),
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
