const express = require("express");
const router = express.Router();
const livreController = require("../controllers/livre.controller");
const auth = require("../middlewares/auth.middleware");

/**
 * @swagger
 * /api/livres:
 *   get:
 *     summary: Récupérer tous les livres
 *     tags: [Livres]
 *     responses:
 *       200:
 *         description: Liste des livres avec auteur et catégorie
 *       500:
 *         description: Erreur serveur
 */
router.get("/", livreController.getAll);

/**
 * @swagger
 * /api/livres/{id}:
 *   get:
 *     summary: Récupérer un livre par ID
 *     tags: [Livres]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du livre
 *     responses:
 *       200:
 *         description: Détails du livre
 *       500:
 *         description: Erreur serveur
 */
router.get("/:id", livreController.getOne);

/**
 * @swagger
 * /api/livres:
 *   post:
 *     summary: Créer un nouveau livre
 *     tags: [Livres]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - libelle
 *               - auteur_id
 *               - categorie_id
 *             properties:
 *               libelle:
 *                 type: string
 *               description:
 *                 type: string
 *               auteur_id:
 *                 type: integer
 *               categorie_id:
 *                 type: integer
 *               created_at:
 *                 type: string
 *                 format: date-time
 *                 description: Timestamp de création (optionnel, généré automatiquement si absent)
 *     responses:
 *       201:
 *         description: Livre créé
 *       401:
 *         description: Non autorisé
 *       500:
 *         description: Erreur serveur
 */
router.post("/", auth, livreController.create);

/**
 * @swagger
 * /api/livres/{id}:
 *   put:
 *     summary: Modifier un livre
 *     tags: [Livres]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du livre
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               libelle:
 *                 type: string
 *               description:
 *                 type: string
 *               auteur_id:
 *                 type: integer
 *               categorie_id:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Livre mis à jour
 *       401:
 *         description: Non autorisé
 *       500:
 *         description: Erreur serveur
 */
router.put("/:id", auth, livreController.update);

/**
 * @swagger
 * /api/livres/{id}:
 *   delete:
 *     summary: Supprimer un livre
 *     tags: [Livres]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du livre
 *     responses:
 *       200:
 *         description: Livre supprimé
 *       401:
 *         description: Non autorisé
 *       500:
 *         description: Erreur serveur
 */
router.delete("/:id", auth, livreController.remove);

module.exports = router;
