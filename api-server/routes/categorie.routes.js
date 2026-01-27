const express = require("express");
const router = express.Router();
const categorieController = require("../controllers/categorie.controller");

/**
 * @swagger
 * /api/categories:
 *   get:
 *     summary: Récupérer toutes les catégories
 *     tags: [Catégories]
 *     responses:
 *       200:
 *         description: Liste des catégories
 *       500:
 *         description: Erreur serveur
 */
router.get("/", categorieController.getAll);

/**
 * @swagger
 * /api/categories/{id}:
 *   get:
 *     summary: Récupérer une catégorie par ID
 *     tags: [Catégories]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la catégorie
 *     responses:
 *       200:
 *         description: Détails de la catégorie
 *       500:
 *         description: Erreur serveur
 */
router.get("/:id", categorieController.getOne);

/**
 * @swagger
 * /api/categories:
 *   post:
 *     summary: Créer une nouvelle catégorie
 *     tags: [Catégories]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - libelle
 *             properties:
 *               libelle:
 *                 type: string
 *               created_at:
 *                 type: string
 *                 format: date-time
 *                 description: Timestamp de création (optionnel, généré automatiquement si absent)
 *     responses:
 *       201:
 *         description: Catégorie créée
 *       500:
 *         description: Erreur serveur
 */
router.post("/", categorieController.create);

/**
 * @swagger
 * /api/categories/{id}:
 *   put:
 *     summary: Modifier une catégorie
 *     tags: [Catégories]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la catégorie
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               libelle:
 *                 type: string
 *     responses:
 *       200:
 *         description: Catégorie mise à jour
 *       500:
 *         description: Erreur serveur
 */
router.put("/:id", categorieController.update);

/**
 * @swagger
 * /api/categories/{id}:
 *   delete:
 *     summary: Supprimer une catégorie
 *     tags: [Catégories]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la catégorie
 *     responses:
 *       200:
 *         description: Catégorie supprimée
 *       500:
 *         description: Erreur serveur
 */
router.delete("/:id", categorieController.remove);

module.exports = router;
