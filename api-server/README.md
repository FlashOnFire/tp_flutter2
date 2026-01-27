# Bibliotheca API Server

API REST pour gérer une bibliothèque (livres, auteurs, catégories) avec documentation Swagger.

## Démarrage rapide

### Avec Docker (Recommandé)

```bash
# Démarrer les conteneurs
docker-compose up -d

# Voir les logs
docker-compose logs -f

# Arrêter les conteneurs
docker-compose down

# Reconstruire et redémarrer
docker-compose down && docker-compose up -d --build
```

### Sans Docker

```bash
# Installer les dépendances
npm install

# Créer un fichier .env avec vos paramètres MySQL
cp .env.example .env

# Démarrer le serveur
npm start
```

## Documentation Swagger

Une fois le serveur démarré, la documentation interactive Swagger est disponible à :

**http://localhost:3000/api-docs/**

Cette interface permet de :
- Voir tous les endpoints disponibles
- Tester les requêtes directement depuis le navigateur
- Voir les schémas de données (modèles)
- Consulter les codes de réponse possibles

## Endpoints disponibles

### Santé du serveur
- `GET /health` - Vérifier l'état du serveur et de la base de données

### Catégories
- `GET /api/categorie` - Récupérer toutes les catégories
- `GET /api/categorie/:id` - Récupérer une catégorie par ID
- `POST /api/categorie` - Créer une nouvelle catégorie
- `PUT /api/categorie/:id` - Modifier une catégorie
- `DELETE /api/categorie/:id` - Supprimer une catégorie

### Auteurs
- `GET /api/auteurs` - Récupérer tous les auteurs
- `GET /api/auteurs/:id` - Récupérer un auteur par ID
- `POST /api/auteurs` - Créer un nouvel auteur
- `PUT /api/auteurs/:id` - Modifier un auteur
- `DELETE /api/auteurs/:id` - Supprimer un auteur

### Livres
- `GET /api/livres` - Récupérer tous les livres (avec infos auteur et catégorie)
- `GET /api/livres/:id` - Récupérer un livre par ID
- `POST /api/livres` - Créer un nouveau livre
- `PUT /api/livres/:id` - Modifier un livre
- `DELETE /api/livres/:id` - Supprimer un livre

## Exemples de requêtes

### Créer une catégorie
```bash
curl -X POST http://localhost:3000/api/categorie \
  -H "Content-Type: application/json" \
  -d '{"libelle":"Science-Fiction"}'
```

### Créer un auteur
```bash
curl -X POST http://localhost:3000/api/auteurs \
  -H "Content-Type: application/json" \
  -d '{"nom":"Asimov","prenoms":"Isaac","email":"isaac@example.com"}'
```

### Créer un livre
```bash
curl -X POST http://localhost:3000/api/livres \
  -H "Content-Type: application/json" \
  -d '{"libelle":"Fondation","description":"Premier tome","auteur_id":1,"categorie_id":1}'
```

### Lister toutes les catégories
```bash
curl http://localhost:3000/api/categorie
```

## Configuration

Le fichier `.env` contient les paramètres de connexion à la base de données :

```env
DB_HOST=mysql
DB_USER=root
DB_PASSWORD=rootpassword
DB_NAME=bibliotheca
PORT=3000
```

## Architecture Docker

Le projet utilise deux conteneurs :
- **bibliotheca-mysql** : Base de données MySQL 8.0
- **bibliotheca-api** : Serveur Node.js Express

La base de données est initialisée automatiquement avec le schéma défini dans `init.sql`.

## Dépendances principales

- **express** - Framework web
- **mysql2** - Client MySQL
- **cors** - Gestion CORS
- **swagger-ui-express** - Interface Swagger UI
- **swagger-jsdoc** - Génération de specs OpenAPI depuis JSDoc
- **dotenv** - Gestion des variables d'environnement

## Développement

Pour modifier la documentation Swagger, éditez les commentaires JSDoc dans `server.js` ou la configuration dans `swagger.js`.

Exemple de commentaire JSDoc :
```javascript
/**
 * @swagger
 * /api/exemple:
 *   get:
 *     summary: Description de l'endpoint
 *     tags: [Tag]
 *     responses:
 *       200:
 *         description: Réponse réussie
 */
```

## Notes

- Le serveur attend que MySQL soit prêt avant de démarrer (5 tentatives max)
- CORS est activé pour tous les domaines
- Les données initiales sont chargées depuis `init.sql`
