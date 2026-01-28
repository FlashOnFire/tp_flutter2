# Bibliotheca - Application de gestion de bibliothèque

Application Flutter avec API REST Node.js/Express et base de données MySQL pour gérer une bibliothèque (livres, auteurs, catégories).
Guillaume CALDERON
Thibaut LARACINE

## Prérequis

- Docker et Docker Compose
- Flutter SDK (ou FVM)

## Installation et lancement

### 1. Démarrer le serveur API

```bash
cd api-server
docker compose down -v
docker compose up -d --build
```
Vérifier que l'API fonctionne :
```bash
curl http://localhost:3000/api/categories
```

### 2. Lancer l'application Flutter

Installer les dépendances :
```bash
flutter pub get
```

Lancer l'application :
```bash
flutter run -d linux
```

## Fonctionnalités

### Synchronisation automatique

L'application synchronise automatiquement les données entre la base locale SQLite et le serveur distant toutes les 30 secondes.

- La synchronisation est bidirectionnelle (upload et download)
- Résolution de conflits basée sur les timestamps `updated_at`
- La suppression est gérée via un field `is_deleted` (détaillé plus bas)

### Authentification

Authentification via JWT pour sécuriser les endpoints de modification des données.
Identifiants par défaut :
- Email : `admin@mail.com`
- Mot de passe : `admin123`

## Swagger

La documentation Swagger est accessible à l'adresse `http://localhost:3000/api-docs`

## Base de données

### Tables

- `auteur` : id, nom, prenom, mail, is_deleted, updated_at
- `categorie` : id, libelle, is_deleted, updated_at
- `livre` : id, libelle, description, auteur_id, categorie_id, is_deleted, updated_at
- `sync_metadata` : key, value

### Soft-Delete

Les suppressions utilisent un mécanisme de "soft-delete" :
- Les éléments supprimés ne sont pas réellement effacés, mais marqués avec `is_deleted = 1`
- Le champ `updated_at` est mis à jour lors de la suppression pour la synchronisation
- Les listes n'affichent que les éléments avec `is_deleted = 0`
- Les conflits sont résolus en comparant les timestamps : la modification la plus récente gagne

### Sync-Metadata
La table `sync_metadata` stocke des informations de synchronisation.
Actuellement, elle contient uniquement un champ 'last_sync' indiquant la date et l'heure de la dernière synchronisation réussie.
Ce champ est mis à jour après chaque synchronisation complète et est utilisé pour déterminer les modifications à synchroniser.


### Résolution de conflits

Si un objet existe à la fois localement et sur le serveur :
- Comparaison des timestamps `updated_at`
- La version la plus récente est conservée
- Les suppressions sont traitées comme des modifications : si la suppression est plus récente qu'une modification, l'élément reste supprimé

## Arrêt des services

### Arrêter l'API

```bash
cd api-server
docker compose down
```

## Réinitialisation

### Réinitialiser la base de données API

```bash
cd api-server
docker compose down -v
docker compose up -d --build
```

### Réinitialiser la base de données Flutter

```bash
rm -rf .dart_tool/sqflite_common_ffi/databases/
```

## Logs

### Logs API

```bash
docker logs bibliotheca-api
```

### Logs MySQL

```bash
docker logs bibliotheca-mysql
```

### Logs Flutter

Les logs apparaissent directement dans le terminal où l'application a été lancée.

