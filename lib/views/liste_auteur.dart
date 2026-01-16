import 'package:flutter/material.dart';
import 'package:tp_flutter2/models/auteur.dart';
import 'package:tp_flutter2/models/database/dao.dart';
import 'package:tp_flutter2/views/edition_auteur.dart';

class ListeAuteur extends StatefulWidget {
  const ListeAuteur({Key? key}) : super(key: key);

  @override
  State<ListeAuteur> createState() => _ListeAuteurState();
}

class _ListeAuteurState extends State<ListeAuteur> {
  Future<List<Auteur>> _loadAuteurs() async {
    return await Dao.listeAuteur();
  }

  void _refreshList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Liste des auteurs")),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditionAuteur()),
        );
        _refreshList();
      },
    ),
    body: FutureBuilder<List<Auteur>>(
      future: _loadAuteurs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final auteurs = snapshot.data ?? [];

        if (auteurs.isEmpty) {
          return const Center(child: Text('Aucun auteur'));
        }

        return ListView.builder(
          itemCount: auteurs.length,
          itemBuilder: (context, i) {
            final auteur = auteurs[i];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text('${auteur.nom ?? ''} ${auteur.prenoms ?? ''}'),
              subtitle: Text(auteur.email ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmer la suppression'),
                      content: Text('Voulez-vous vraiment supprimer "${auteur.nom} ${auteur.prenoms}" ?'),
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

                  if (confirm == true && auteur.id != null) {
                    await Dao.deleteAuteur(auteur.id!);
                    _refreshList();
                  }
                },
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditionAuteur(auteur: auteur),
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
