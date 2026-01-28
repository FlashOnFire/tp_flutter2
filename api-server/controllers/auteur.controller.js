const db = require("../config/db");

exports.getAll = (req, res) => {
  db.query("SELECT * FROM auteur WHERE is_deleted = 0", (err, results) => {
    if (err) return res.status(500).json(err);
    res.json(results);
  });
};

exports.getOne = (req, res) => {
  db.query(
    "SELECT * FROM auteur WHERE id = ?",
    [req.params.id],
    (err, results) => {
      if (err) return res.status(500).json(err);
      res.json(results[0]);
    }
  );
};

exports.create = (req, res) => {
  const { nom, prenom, mail, updated_at, is_deleted } = req.body;
  const timestamp = updated_at
    ? updated_at.replace('T', ' ').substring(0, 19)
    : new Date().toISOString().slice(0, 19).replace('T', ' ');
  const deleted = is_deleted ? 1 : 0;

  db.query(
    "INSERT INTO auteur (nom, prenom, mail, is_deleted, updated_at) VALUES (?, ?, ?, ?, ?)",
    [nom, prenom, mail, deleted, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({
        id: result.insertId,
        nom,
        prenom,
        mail,
        is_deleted: deleted,
        updated_at: timestamp
      });
    }
  );
};

exports.update = (req, res) => {
  const { nom, prenom, mail, updated_at, is_deleted } = req.body;
  const timestamp = updated_at
    ? updated_at.replace('T', ' ').substring(0, 19)
    : new Date().toISOString().slice(0, 19).replace('T', ' ');
  const deleted = is_deleted !== undefined ? (is_deleted ? 1 : 0) : 0;

  db.query(
    "UPDATE auteur SET nom=?, prenom=?, mail=?, is_deleted=?, updated_at=? WHERE id=?",
    [nom, prenom, mail, deleted, timestamp, req.params.id],
    (err, result) => {
      if (err) return res.status(500).json(err);
      if (result.affectedRows === 0) {
        return res.status(404).json({ message: "Auteur non trouvé" });
      }
      res.json({ message: "Auteur mis à jour", is_deleted: deleted, updated_at: timestamp });
    }
  );
};

exports.remove = (req, res) => {
  const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
  db.query(
    "UPDATE auteur SET is_deleted=1, updated_at=? WHERE id=?",
    [timestamp, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Auteur supprimé", is_deleted: 1, updated_at: timestamp });
    }
  );
};
