const express = require("express");
const router = express.Router();
const auteurController = require("../controllers/auteur.controller");

/**
 * @swagger
 * /api/auteurs:
 *   get:
 *     summary: Récupérer tous les auteurs
 *     tags: [Auteurs]
 *     responses:
 *       200:
 *         description: Liste des auteurs
 *       500:
 *         description: Erreur serveur
 */
router.get("/", auteurController.getAll);

/**
 * @swagger
 * /api/auteurs/{id}:
 *   get:
 *     summary: Récupérer un auteur par ID
 *     tags: [Auteurs]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de l'auteur
 *     responses:
 *       200:
 *         description: Détails de l'auteur
 *       500:
 *         description: Erreur serveur
 */
router.get("/:id", auteurController.getOne);

/**
 * @swagger
 * /api/auteurs:
 *   post:
 *     summary: Créer un nouvel auteur
 *     tags: [Auteurs]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nom
 *               - prenom
 *             properties:
 *               nom:
 *                 type: string
 *               prenom:
 *                 type: string
 *               mail:
 *                 type: string
 *               created_at:
 *                 type: string
 *                 format: date-time
 *                 description: Timestamp de création (optionnel, généré automatiquement si absent)
 *     responses:
 *       201:
 *         description: Auteur créé
 *       500:
 *         description: Erreur serveur
 */
router.post("/", auteurController.create);

/**
 * @swagger
 * /api/auteurs/{id}:
 *   put:
 *     summary: Modifier un auteur
 *     tags: [Auteurs]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de l'auteur
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nom:
 *                 type: string
 *               prenom:
 *                 type: string
 *               mail:
 *                 type: string
 *     responses:
 *       200:
 *         description: Auteur mis à jour
 *       500:
 *         description: Erreur serveur
 */
router.put("/:id", auteurController.update);

/**
 * @swagger
 * /api/auteurs/{id}:
 *   delete:
 *     summary: Supprimer un auteur
 *     tags: [Auteurs]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de l'auteur
 *     responses:
 *       200:
 *         description: Auteur supprimé
 *       500:
 *         description: Erreur serveur
 */
router.delete("/:id", auteurController.remove);

module.exports = router;
