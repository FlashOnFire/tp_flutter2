import 'package:flutter/material.dart';
import 'package:tp_flutter2/models/auteur.dart';
import 'package:tp_flutter2/models/database/dao.dart';

class EditionAuteur extends StatefulWidget {
  final Auteur? auteur;

  const EditionAuteur({Key? key, this.auteur}) : super(key: key);

  @override
  State<EditionAuteur> createState() => _EditionAuteurState();
}

class _EditionAuteurState extends State<EditionAuteur> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomsController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.auteur != null) {
      _nomController.text = widget.auteur!.nom ?? '';
      _prenomsController.text = widget.auteur!.prenoms ?? '';
      _emailController.text = widget.auteur!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomsController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveAuteur() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.auteur == null) {
          // Create new auteur
          final newAuteur = Auteur(
            nom: _nomController.text,
            prenoms: _prenomsController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
          );
          await Dao.createAuteur(newAuteur);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Auteur créé avec succès')),
            );
            Navigator.pop(context);
          }
        } else {
          // Update existing auteur
          widget.auteur!.nom = _nomController.text;
          widget.auteur!.prenoms = _prenomsController.text;
          widget.auteur!.email = _emailController.text.isEmpty ? null : _emailController.text;
          await Dao.updateAuteur(widget.auteur!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Auteur mis à jour avec succès')),
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
      title: Text(widget.auteur == null
        ? "Nouvel auteur"
        : "Modifier auteur"),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: "Nom"),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _prenomsController,
            decoration: const InputDecoration(labelText: "Prénoms"),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer des prénoms';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveAuteur,
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    ),
  );
}
