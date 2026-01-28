const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'bibliotheca',
  password: process.env.DB_PASSWORD || 'bibliotheca123',
  database: process.env.DB_NAME || 'bibliotheca',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

try {
  const connection = await pool.getConnection();
  console.log('Connexion à MySQL réussie!');
  connection.release();
  return true;
} catch (error) {
  console.error('Impossible de se connecter à MySQL:', error.message);
  process.exit(1);
}

module.exports = pool;

