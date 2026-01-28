import 'package:flutter/material.dart';
import 'package:tp_flutter2/models/categorie.dart';
import 'package:tp_flutter2/models/database/dao.dart';
import 'package:tp_flutter2/views/edition_categorie.dart';

class ListeCategorie extends StatefulWidget {
  const ListeCategorie({super.key});

  @override
  State<ListeCategorie> createState() => _ListeCategorieState();
}

class _ListeCategorieState extends State<ListeCategorie> {
  Future<List<Categorie>> _loadCategories() async {
    return await Dao.listeCategorie();
  }

  void _refreshList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Liste des catégories")),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditionCategorie()),
        );
        _refreshList();
      },
    ),
    body: FutureBuilder<List<Categorie>>(
      future: _loadCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return const Center(child: Text('Aucune catégorie'));
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final categorie = categories[i];
            return ListTile(
              leading: const Icon(Icons.book),
              title: Text(categorie.libelle ?? 'Sans nom'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmer la suppression'),
                      content: Text('Voulez-vous vraiment supprimer "${categorie.libelle}" ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && categorie.id != null) {
                    await Dao.delete(categorie.id!);
                    _refreshList();
                  }
                },
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditionCategorie(categorie: categorie),
                  ),
                );
                _refreshList();
              },
            );
          },
        );
      },
    ),
  );
}
