#!/bin/bash

# Script de test de l'API Bibliotheca

echo "==================================="
echo "🧪 Tests de l'API Bibliotheca"
echo "==================================="
echo ""

# Vérifier que l'API est en ligne
echo "1️⃣  Test de santé de l'API..."
curl -s http://localhost:3000/health | jq
echo ""

# Récupérer toutes les catégories
echo "2️⃣  Récupération de toutes les catégories..."
curl -s http://localhost:3000/api/categorie | jq
echo ""

# Créer une nouvelle catégorie
echo "3️⃣  Création d'une nouvelle catégorie..."
NEW_CAT=$(curl -s -X POST http://localhost:3000/api/categorie \
  -H "Content-Type: application/json" \
  -d '{"libelle":"Bande Dessinée"}')
echo $NEW_CAT | jq
CAT_ID=$(echo $NEW_CAT | jq -r '.id')
echo ""

# Modifier la catégorie
echo "4️⃣  Modification de la catégorie..."
curl -s -X PUT http://localhost:3000/api/categorie/$CAT_ID \
  -H "Content-Type: application/json" \
  -d '{"libelle":"BD & Comics"}' | jq
echo ""

# Récupérer tous les auteurs
echo "5️⃣  Récupération de tous les auteurs..."
curl -s http://localhost:3000/api/auteurs | jq
echo ""

# Créer un nouvel auteur
echo "6️⃣  Création d'un nouvel auteur..."
NEW_AUTHOR=$(curl -s -X POST http://localhost:3000/api/auteurs \
  -H "Content-Type: application/json" \
  -d '{"nom":"Tolkien","prenoms":"J.R.R.","email":"tolkien@example.com"}')
echo $NEW_AUTHOR | jq
AUTHOR_ID=$(echo $NEW_AUTHOR | jq -r '.id')
echo ""

# Créer un nouveau livre
echo "7️⃣  Création d'un nouveau livre..."
curl -s -X POST http://localhost:3000/api/livres \
  -H "Content-Type: application/json" \
  -d "{\"libelle\":\"Le Seigneur des Anneaux\",\"description\":\"Une épopée fantastique légendaire\",\"auteur_id\":$AUTHOR_ID,\"categorie_id\":$CAT_ID}" | jq
echo ""

# Récupérer tous les livres
echo "8️⃣  Récupération de tous les livres (avec jointures)..."
curl -s http://localhost:3000/api/livres | jq
echo ""

# Supprimer la catégorie créée
echo "9️⃣  Suppression de la catégorie de test..."
curl -s -X DELETE http://localhost:3000/api/categorie/$CAT_ID | jq
echo ""

echo "==================================="
echo "✅ Tests terminés!"
echo "==================================="

