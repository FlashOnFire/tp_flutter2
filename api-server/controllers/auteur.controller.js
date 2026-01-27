const db = require("../config/db");

exports.getAll = (req, res) => {
  db.query("SELECT * FROM auteur", (err, results) => {
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
  const { nom, prenom, mail, created_at } = req.body;
  const timestamp = created_at || new Date().toISOString().slice(0, 19).replace('T', ' ');

  db.query(
    "INSERT INTO auteur (nom, prenom, mail, created_at) VALUES (?, ?, ?, ?)",
    [nom, prenom, mail, timestamp],
    (err, result) => {
      if (err) return res.status(500).json(err);
      res.status(201).json({ id: result.insertId, created_at: timestamp });
    }
  );
};

exports.update = (req, res) => {
  const { nom, prenom, mail } = req.body;
  db.query(
    "UPDATE auteur SET nom=?, prenom=?, mail=? WHERE id=?",
    [nom, prenom, mail, req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Auteur mis à jour" });
    }
  );
};

exports.remove = (req, res) => {
  db.query(
    "DELETE FROM auteur WHERE id=?",
    [req.params.id],
    (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: "Auteur supprimé" });
    }
  );
};
