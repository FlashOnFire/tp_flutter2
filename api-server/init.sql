-- Création des tables pour Bibliotheca

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

CREATE TABLE IF NOT EXISTS auteur (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(255) NOT NULL,
  prenom VARCHAR(255) NOT NULL,
  mail VARCHAR(255),
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS categorie (
  id INT AUTO_INCREMENT PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS livre (
  id INT AUTO_INCREMENT PRIMARY KEY,
  libelle VARCHAR(255) NOT NULL,
  description TEXT,
  auteur_id INT NOT NULL,
  categorie_id INT NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (auteur_id) REFERENCES auteur(id) ON DELETE CASCADE,
  FOREIGN KEY (categorie_id) REFERENCES categorie(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Données de test

INSERT INTO categorie (libelle) VALUES
  ('Roman'),
  ('Science-Fiction'),
  ('Poésie'),
  ('Essai'),
  ('Thriller');

INSERT INTO auteur (nom, prenom, mail) VALUES
  ('Hugo', 'Victor', 'victor.hugo@example.com'),
  ('Asimov', 'Isaac', 'isaac.asimov@example.com'),
  ('Baudelaire', 'Charles', 'charles.baudelaire@example.com'),
  ('Camus', 'Albert', 'albert.camus@example.com');

INSERT INTO livre (libelle, description, auteur_id, categorie_id) VALUES
  ('Les Misérables', 'Un chef-d\'œuvre de la littérature française', 1, 1),
  ('Foundation', 'Le cycle de Fondation, une saga de science-fiction épique', 2, 2),
  ('Les Fleurs du Mal', 'Recueil de poèmes', 3, 3),
  ('L\'Étranger', 'Roman philosophique existentialiste', 4, 1);

