const db = require("../config/db");

exports.getAll = (req, res) => {
  const sql = `
    SELECT livre.id, livre.libelle, livre.description,
           livre.auteur_id, livre.categorie_id,
           auteur.nom AS auteur_nom, auteur.prenom,
           categorie.libelle AS categorie,
           livre.is_deleted,
           livre.updated_at
    FROM livre
    JOIN auteur ON livre.auteur_id = auteur.id
    JOIN categorie ON livre.categorie_id = categorie.id
    WHERE livre.is_deleted = 0
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
  const { libelle, description, auteur_id, categorie_id, updated_at, is_deleted } = req.body;
  const timestamp = updated_at ? new Date(updated_at).toISOString().slice(0, 19).replace('T', ' ') : new Date().toISOString().slice(0, 19).replace('T', ' ');
  const deleted = is_deleted ? 1 : 0;

  db.query(
    "INSERT INTO livre (libelle, description, auteur_id, categorie_id, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
    [libelle, description, auteur_id, categorie_id, deleted, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({
        id: result.insertId,
        libelle,
        description,
        auteur_id,
        categorie_id,
        is_deleted: deleted,
        updated_at: timestamp
      });
    }
  );
};

exports.update = (req, res) => {
  const { libelle, description, auteur_id, categorie_id, updated_at, is_deleted } = req.body;
  const timestamp = updated_at ? new Date(updated_at).toISOString().slice(0, 19).replace('T', ' ') : new Date().toISOString().slice(0, 19).replace('T', ' ');
  const deleted = is_deleted !== undefined ? (is_deleted ? 1 : 0) : 0;

  db.query(
    "UPDATE livre SET libelle=?, description=?, auteur_id=?, categorie_id=?, is_deleted=?, updated_at=? WHERE id=?",
    [libelle, description, auteur_id, categorie_id, deleted, timestamp, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Livre mis à jour", is_deleted: deleted, updated_at: timestamp });
    }
  );
};

exports.remove = (req, res) => {
  const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
  db.query(
    "UPDATE livre SET is_deleted=1, updated_at=? WHERE id=?",
    [timestamp, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Livre supprimé", is_deleted: 1, updated_at: timestamp });
    }
  );
};
