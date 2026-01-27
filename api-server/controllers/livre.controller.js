const db = require("../config/db");

exports.getAll = (req, res) => {
  const sql = `
    SELECT livre.id, livre.libelle, livre.description,
           auteur.nom AS auteur_nom, auteur.prenom,
           categorie.libelle AS categorie,
           livre.created_at
    FROM livre
    JOIN auteur ON livre.auteur_id = auteur.id
    JOIN categorie ON livre.categorie_id = categorie.id
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
};

exports.getOne = (req, res) => {
  db.query(
    "SELECT * FROM livre WHERE id=?",
    [req.params.id],
    (err, results) => {
      if (err) return res.status(500).json(err);
      res.json(results[0]);
    }
  );
};

exports.create = (req, res) => {
  const { libelle, description, auteur_id, categorie_id, created_at } = req.body;
  const timestamp = created_at || new Date().toISOString().slice(0, 19).replace('T', ' ');

  db.query(
    "INSERT INTO livre (libelle, description, auteur_id, categorie_id, created_at) VALUES (?, ?, ?, ?, ?)",
    [libelle, description, auteur_id, categorie_id, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({ id: result.insertId, created_at: timestamp });
    }
  );
};

exports.update = (req, res) => {
  const { libelle, description, auteur_id, categorie_id } = req.body;
  db.query(
    "UPDATE livre SET libelle=?, description=?, auteur_id=?, categorie_id=? WHERE id=?",
    [libelle, description, auteur_id, categorie_id, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Livre mis à jour" });
    }
  );
};

exports.remove = (req, res) => {
  db.query(
    "DELETE FROM livre WHERE id=?",
    [req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Livre supprimé" });
    }
  );
};
