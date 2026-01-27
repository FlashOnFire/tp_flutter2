const express = require("express");
const jwt = require("jsonwebtoken");
const router = express.Router();

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Authentification et génération du token JWT
 *     tags: [Authentification]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 example: admin@mail.com
 *               password:
 *                 type: string
 *                 example: admin123
 *     responses:
 *       200:
 *         description: Token JWT généré avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *       401:
 *         description: Identifiants invalides
 */
router.post("/login", (req, res) => {
  const { email, password } = req.body;

  if (email === "admin@mail.com" && password === "admin123") {
    const token = jwt.sign(
      { email, role: "admin" },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
    return res.json({ token });
  }

  res.status(401).json({ message: "Identifiants invalides" });
});

module.exports = router;
