import 'package:flutter/material.dart';
import 'package:tp_flutter2/models/auteur.dart';
import 'package:tp_flutter2/models/categorie.dart';

class EditionLivre extends StatefulWidget {
  const EditionLivre({Key? key}) : super(key: key);

  @override
  State<EditionLivre> createState() => _EditionLivreState();
}

class _EditionLivreState extends State<EditionLivre> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Edition de livre")),
    body: Form(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MaterialButton(
            onPressed: () {},
            child: const CircleAvatar(radius: 50, child: Icon(Icons.book)),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: "Titre du livre"),
          ),
          DropdownButtonFormField<Categorie>(
            items: [
              DropdownMenuItem(
                value: Categorie(id: 1),
                child: Text("Catégorie 1"),
              ),
              DropdownMenuItem(
                value: Categorie(id: 2),
                child: Text("Catégorie 2"),
              ),
            ],
            onChanged: (value) {},
            decoration: const InputDecoration(labelText: "Catégorie"),
          ),
          DropdownButtonFormField<Auteur>(
            items: [
              DropdownMenuItem(value: Auteur(id: 1), child: Text("Auteur 1")),
              DropdownMenuItem(value: Auteur(id: 2), child: Text("Auteur 2")),
            ],
            onChanged: (value) {},
            decoration: const InputDecoration(labelText: "Auteur"),
          ),
          TextFormField(
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: "Description du livre",
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text("Enregistrer")),
        ],
      ),
    ),
  );
}
