import 'package:flutter/material.dart';
import 'package:tp_flutter2/models/categorie.dart';
import 'package:tp_flutter2/models/database/dao.dart';

class EditionCategorie extends StatefulWidget {
  final Categorie? categorie;

  const EditionCategorie({Key? key, this.categorie}) : super(key: key);

  @override
  State<EditionCategorie> createState() => _EditionCategorieState();
}

class _EditionCategorieState extends State<EditionCategorie> {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.categorie != null) {
      _libelleController.text = widget.categorie!.libelle ?? '';
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    super.dispose();
  }

  Future<void> _saveCategorie() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.categorie == null) {
          // Create new category
          final newCategorie = Categorie(libelle: _libelleController.text);
          await Dao.createCategorie(newCategorie);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catégorie créée avec succès')),
            );
            Navigator.pop(context);
          }
        } else {
          // Update existing category
          widget.categorie!.libelle = _libelleController.text;
          await Dao.updateCategorie(widget.categorie!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catégorie mise à jour avec succès')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.categorie == null
        ? "Nouvelle catégorie"
        : "Modifier catégorie"),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _libelleController,
            decoration: const InputDecoration(labelText: "Nom catégorie"),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom de catégorie';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveCategorie,
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    ),
  );
}
