-- Création des tables pour Bibliotheca

CREATE TABLE IF NOT EXISTS auteur (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  prenom VARCHAR(255) NOT NULL,
  mail VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categorie (
  id INT AUTO_INCREMENT PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS livre (
  id INT AUTO_INCREMENT PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  description TEXT,
  auteur_id INT NOT NULL,
  categorie_id INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (auteur_id) REFERENCES auteur(id) ON DELETE CASCADE,
  FOREIGN KEY (categorie_id) REFERENCES categorie(id) ON DELETE CASCADE
);

-- Données de test

INSERT INTO categorie (libelle, created_at) VALUES
  ('Roman', NOW()),
  ('Science-Fiction', NOW()),
  ('Poésie', NOW()),
  ('Essai', NOW()),
  ('Thriller', NOW());

INSERT INTO auteur (nom, prenom, mail, created_at) VALUES
  ('Hugo', 'Victor', 'victor.hugo@example.com', NOW()),
  ('Asimov', 'Isaac', 'isaac.asimov@example.com', NOW()),
  ('Baudelaire', 'Charles', 'charles.baudelaire@example.com', NOW()),
  ('Camus', 'Albert', 'albert.camus@example.com', NOW());

INSERT INTO livre (libelle, description, auteur_id, categorie_id, created_at) VALUES
  ('Les Misérables', 'Un chef-d\'œuvre de la littérature française', 1, 1, NOW()),
  ('Foundation', 'Le cycle de Fondation, une saga de science-fiction épique', 2, 2, NOW()),
  ('Les Fleurs du Mal', 'Recueil de poèmes', 3, 3, NOW()),
  ('L\'Étranger', 'Roman philosophique existentialiste', 4, 1, NOW());

