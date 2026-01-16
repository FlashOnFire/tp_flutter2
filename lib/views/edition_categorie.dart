import 'package:flutter/material.dart';

class EditionCategorie extends StatefulWidget {
  const EditionCategorie({Key? key}) : super(key: key);

  @override
  State<EditionCategorie> createState() => _EditionCategorieState();
}

class _EditionCategorieState extends State<EditionCategorie> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Edition de catégorie")),
    body: Form(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: "Nom catégorie"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text("Enregistrer")),
        ],
      ),
    ),
  );
}
