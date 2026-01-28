const db = require("../config/db");

exports.getAll = (req, res) => {
  db.query("SELECT * FROM categorie WHERE is_deleted = 0", (err, results) => {
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
  const { libelle, updated_at, is_deleted } = req.body;
  const timestamp = updated_at ? new Date(updated_at).toISOString().slice(0, 19).replace('T', ' ') : new Date().toISOString().slice(0, 19).replace('T', ' ');
  const deleted = is_deleted ? 1 : 0;

  db.query(
    "INSERT INTO categorie (libelle, is_deleted, updated_at) VALUES (?, ?, ?)",
    [libelle, deleted, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({
        id: result.insertId,
        libelle,
        is_deleted: deleted,
        updated_at: timestamp
      });
    }
  );
};

exports.update = (req, res) => {
  const { libelle, updated_at, is_deleted } = req.body;
  const timestamp = updated_at ? new Date(updated_at).toISOString().slice(0, 19).replace('T', ' ') : new Date().toISOString().slice(0, 19).replace('T', ' ');
  const deleted = is_deleted !== undefined ? (is_deleted ? 1 : 0) : 0;

  db.query(
    "UPDATE categorie SET libelle=?, is_deleted=?, updated_at=? WHERE id=?",
    [libelle, deleted, timestamp, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Catégorie mise à jour", is_deleted: deleted, updated_at: timestamp });
    }
  );
};

exports.remove = (req, res) => {
  const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
  db.query(
    "UPDATE categorie SET is_deleted=1, updated_at=? WHERE id=?",
    [timestamp, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Catégorie supprimée", is_deleted: 1, updated_at: timestamp });
    }
  );
};
