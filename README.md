# Bibliotheca - Application de gestion de bibliothèque

Application Flutter avec API REST Node.js/Express et base de données MySQL pour gérer une bibliothèque (livres, auteurs, catégories).

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

Supprimer l'ancienne base de données locale (si elle existe) :
```bash
rm -rf .dart_tool/sqflite_common_ffi/databases/
```

Installer les dépendances :
```bash
flutter pub get
```

Lancer l'application :
```bash
flutter run -d linux
```

Ou avec FVM :
```bash
fvm flutter pub get
fvm flutter run -d linux
```

## Fonctionnalités

### Synchronisation automatique

L'application synchronise automatiquement les données entre la base locale SQLite et le serveur distant toutes les 30 secondes.

La synchronisation est bidirectionnelle (upload et download)
 Résolution de conflits basée sur les timestamps
- Fonctionnement hors ligne complet

### Gestion des données

- Catégories : consultation et gestion des catégories de livres
- Auteurs : consultation et gestion des auteurs
- Livres : consultation et gestion des livres (nécessite authentification JWT pour modification)

### Authentification

Identifiants par défaut :
- Email : `admin@mail.com`
- Mot de passe : `admin123`

## Ports utilisés

- API REST : `http://localhost:3000`
- Documentation Swagger : `http://localhost:3000/api-docs`
- MySQL : `localhost:3307`

## Architecture

### Backend (api-server/)

- Node.js + Express
- MySQL 8.0
- JWT pour l'authentification
- Swagger pour la documentation API
- Docker pour le déploiement

### Frontend (Flutter)

- SQLite local pour le stockage hors ligne
- Service de synchronisation automatique
- Interface utilisateur responsive
- Gestion d'état avec StatefulWidget

## Base de données

### Tables

Toutes les tables incluent un champ `created_at` pour la synchronisation :

- `auteur` : id, nom, prenom, mail, created_at
- `categorie` : id, libelle, created_at
- `livre` : id, libelle, description, auteur_id, categorie_id, created_at
- `sync_metadata` : key, value

## Endpoints API

### Public

- `GET /api/categories` - Liste des catégories
- `GET /api/auteurs` - Liste des auteurs
- `GET /api/livres` - Liste des livres (avec JOINs)

### Protégés (JWT requis)

- `POST /api/livres` - Créer un livre
- `PUT /api/livres/:id` - Modifier un livre
- `DELETE /api/livres/:id` - Supprimer un livre

### Authentification

- `POST /api/auth/login` - Obtenir un token JWT

### Principe

1. Les objets créés localement reçoivent un ID négatif temporaire
2. Lors de la synchronisation, ils sont envoyés au serveur
3. Le serveur assigne un ID permanent
4. L'ID local est mis à jour avec l'ID du serveur
5. Les données du serveur sont téléchargées et fusionnées

### Résolution de conflits

Si un objet existe à la fois localement et sur le serveur :
- Comparaison des timestamps `created_at`
- La version la plus récente est conservée

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

Puis relancer l'application Flutter.

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

