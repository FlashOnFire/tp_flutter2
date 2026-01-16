import 'package:flutter/material.dart';
import 'package:tp_flutter2/models/livre.dart';
import 'package:tp_flutter2/models/database/dao.dart';
import 'package:tp_flutter2/views/edition_livre.dart';

class ListeLivrePage extends StatefulWidget {
  const ListeLivrePage({Key? key}) : super(key: key);

  @override
  State<ListeLivrePage> createState() => _ListeLivrePageState();
}

class _ListeLivrePageState extends State<ListeLivrePage> {
  Future<List<Livre>> _loadLivres() async {
    return await Dao.listeLivre();
  }

  void _refreshList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Liste des livres")),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditionLivre()),
        );
        _refreshList();
      },
    ),
    body: FutureBuilder<List<Livre>>(
      future: _loadLivres(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final livres = snapshot.data ?? [];

        if (livres.isEmpty) {
          return const Center(child: Text('Aucun livre'));
        }

        return ListView.builder(
          itemCount: livres.length,
          itemBuilder: (context, i) {
            final livre = livres[i];
            return ListTile(
              leading: const Icon(Icons.book),
              title: Text(livre.libelle ?? 'Sans titre'),
              subtitle: Text(livre.description ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmer la suppression'),
                      content: Text('Voulez-vous vraiment supprimer "${livre.libelle}" ?'),
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

                  if (confirm == true && livre.id != null) {
                    await Dao.deleteLivre(livre.id!);
                    _refreshList();
                  }
                },
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditionLivre(livre: livre),
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
