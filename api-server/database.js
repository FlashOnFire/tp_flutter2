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

// Test de connexion avec retry
async function testConnection(retries = 5, delay = 2000) {
  for (let i = 0; i < retries; i++) {
    try {
      const connection = await pool.getConnection();
      console.log('✅ Connexion à MySQL réussie!');
      connection.release();
      return true;
    } catch (error) {
      console.log(`⏳ Tentative ${i + 1}/${retries} - En attente de MySQL...`);
      if (i < retries - 1) {
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        console.error('❌ Impossible de se connecter à MySQL:', error.message);
        process.exit(1);
      }
    }
  }
}

testConnection();

module.exports = pool;

