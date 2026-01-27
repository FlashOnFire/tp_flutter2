const db = require("../config/db");

exports.getAll = (req, res) => {
  db.query("SELECT * FROM categorie", (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
};

exports.getOne = (req, res) => {
  db.query(
    "SELECT * FROM categorie WHERE id = ?",
    [req.params.id],
    (err, results) => {
      if (err) return res.status(500).json(err);
      res.json(results[0]);
    }
  );
};

exports.create = (req, res) => {
  const { libelle, updated_at } = req.body;
  const timestamp = updated_at ? new Date(updated_at).toISOString().slice(0, 19).replace('T', ' ') : new Date().toISOString().slice(0, 19).replace('T', ' ');

  db.query(
    "INSERT INTO categorie (libelle, updated_at) VALUES (?, ?)",
    [libelle, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({
        id: result.insertId,
        libelle,
        updated_at: timestamp
      });
    }
  );
};

exports.update = (req, res) => {
  const { libelle, updated_at } = req.body;
  const timestamp = updated_at ? new Date(updated_at).toISOString().slice(0, 19).replace('T', ' ') : new Date().toISOString().slice(0, 19).replace('T', ' ');

  db.query(
    "UPDATE categorie SET libelle=?, updated_at=? WHERE id=?",
    [libelle, timestamp, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Catégorie mise à jour", updated_at: timestamp });
    }
  );
};

exports.remove = (req, res) => {
  db.query(
    "DELETE FROM categorie WHERE id=?",
    [req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Catégorie supprimée" });
    }
  );
};
