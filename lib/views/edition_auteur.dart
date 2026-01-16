import 'package:flutter/material.dart';

class EditionAuteur extends StatefulWidget {
  const EditionAuteur({Key? key}) : super(key: key);

  @override
  State<EditionAuteur> createState() => _EditionAuteurState();
}

class _EditionAuteurState extends State<EditionAuteur> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Edition d'auteur")),
    body: Form(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: "Titre du livre"),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: "Prénoms"),
          ),
          TextFormField(decoration: const InputDecoration(labelText: "Email")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text("Enregistrer")),
        ],
      ),
    ),
  );
}
