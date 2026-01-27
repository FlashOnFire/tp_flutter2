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
  const { libelle, created_at } = req.body;
  const timestamp = created_at || new Date().toISOString().slice(0, 19).replace('T', ' ');

  db.query(
    "INSERT INTO categorie (libelle, created_at) VALUES (?, ?)",
    [libelle, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({ id: result.insertId, created_at: timestamp });
    }
  );
};

exports.update = (req, res) => {
  const { libelle } = req.body;
  db.query(
    "UPDATE categorie SET libelle=? WHERE id=?",
    [libelle, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Catégorie mise à jour" });
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
