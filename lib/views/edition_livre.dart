import 'package:flutter/material.dart';
import 'package:tp_flutter2/models/auteur.dart';
import 'package:tp_flutter2/models/categorie.dart';
import 'package:tp_flutter2/models/livre.dart';
import 'package:tp_flutter2/models/database/dao.dart';

class EditionLivre extends StatefulWidget {
  final Livre? livre;

  const EditionLivre({super.key, this.livre});

  @override
  State<EditionLivre> createState() => _EditionLivreState();
}

class _EditionLivreState extends State<EditionLivre> {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Categorie> _categories = [];
  List<Auteur> _auteurs = [];
  Categorie? _selectedCategorie;
  Auteur? _selectedAuteur;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await Dao.listeCategorie();
      final auteurs = await Dao.listeAuteur();

      setState(() {
        _categories = categories;
        _auteurs = auteurs;

        if (widget.livre != null) {
          _libelleController.text = widget.livre!.libelle ?? '';
          _descriptionController.text = widget.livre!.description ?? '';

          // Find selected category
          if (widget.livre!.categorieId != null) {
            _selectedCategorie = _categories.firstWhere(
              (c) => c.id == widget.livre!.categorieId,
              orElse: () => _categories.isNotEmpty ? _categories.first : Categorie(),
            );
          }

          // Find selected auteur
          if (widget.livre!.auteurId != null) {
            _selectedAuteur = _auteurs.firstWhere(
              (a) => a.id == widget.livre!.auteurId,
              orElse: () => _auteurs.isNotEmpty ? _auteurs.first : Auteur(),
            );
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveLivre() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategorie == null || _selectedCategorie!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
        );
        return;
      }

      if (_selectedAuteur == null || _selectedAuteur!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un auteur')),
        );
        return;
      }

      try {
        if (widget.livre == null) {
          // Create new livre
          final newLivre = Livre(
            libelle: _libelleController.text,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            categorieId: _selectedCategorie!.id,
            auteurId: _selectedAuteur!.id,
          );
          await Dao.createLivre(newLivre);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Livre créé avec succès')),
            );
            Navigator.pop(context);
          }
        } else {
          // Update existing livre
          widget.livre!.libelle = _libelleController.text;
          widget.livre!.description = _descriptionController.text.isEmpty ? null : _descriptionController.text;
          widget.livre!.categorieId = _selectedCategorie!.id;
          widget.livre!.auteurId = _selectedAuteur!.id;
          await Dao.updateLivre(widget.livre!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Livre mis à jour avec succès')),
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.livre == null ? "Nouveau livre" : "Modifier livre"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.livre == null ? "Nouveau livre" : "Modifier livre"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(labelText: "Titre du livre"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Categorie>(
              value: _selectedCategorie,
              items: _categories.map((categorie) {
                return DropdownMenuItem(
                  value: categorie,
                  child: Text(categorie.libelle ?? 'Sans nom'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategorie = value;
                });
              },
              decoration: const InputDecoration(labelText: "Catégorie"),
              validator: (value) {
                if (value == null || value.id == null) {
                  return 'Veuillez sélectionner une catégorie';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Auteur>(
              value: _selectedAuteur,
              items: _auteurs.map((auteur) {
                return DropdownMenuItem(
                  value: auteur,
                  child: Text('${auteur.nom ?? ''} ${auteur.prenoms ?? ''}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAuteur = value;
                });
              },
              decoration: const InputDecoration(labelText: "Auteur"),
              validator: (value) {
                if (value == null || value.id == null) {
                  return 'Veuillez sélectionner un auteur';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: "Description du livre",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveLivre,
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
