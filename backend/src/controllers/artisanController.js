const path = require('path');
// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', '..', 'db.config');
const pool = require(dbConfigPath);

const getArtisans = async (req, res, connectedUsers) => {
  try {
    const result = await pool.query(`
      SELECT
        u.id,
        ap.nom_complet AS name,
        ap.specialite AS specialty,
        ap.location,
        ap.photo_url,
        u.role,
        'artisan' as type
      FROM users u
      JOIN artisan_profiles ap ON u.id = ap.user_id
      WHERE u.role = 'artisan'
      UNION
      SELECT
        u.id,
        cp.nom_entreprise AS name,
        cp.type_commerce AS specialty,
        cp.location,
        cp.photo_url,
        u.role,
        'commercant' as type
      FROM users u
      JOIN commercant_profiles cp ON u.id = cp.user_id
      WHERE u.role = 'commercant'
    `);
    const artisans = result.rows.map(artisan => ({
      ...artisan,
      isOnline: connectedUsers.has(artisan.id.toString())
    }));
    res.json(artisans);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const getArtisan = async (req, res, connectedUsers) => {
  try {
    // Validation et parsing sécurisé de l'ID
    const paramValue = req.params.id;
    if (!paramValue || isNaN(paramValue) || parseInt(paramValue) <= 0) {
      return res.status(400).json({ message: 'ID invalide fourni.' });
    }
    
    const professionalId = parseInt(paramValue);

    // 1. Get user role
    const userResult = await pool.query('SELECT role FROM users WHERE id = $1', [professionalId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'Professionnel non trouvé.' });
    }
    const { role } = userResult.rows[0];

    // 2. Get profile based on role
    let profileResult;
    if (role === 'artisan') {
      profileResult = await pool.query(
        'SELECT id, nom_complet AS name, specialite AS specialty, description, location, telephone, annees_experience, siret, site_web, photo_url FROM users u JOIN artisan_profiles ap ON u.id = ap.user_id WHERE u.id = $1',
        [professionalId]
      );
    } else if (role === 'commercant') {
      profileResult = await pool.query(
        'SELECT id, nom_entreprise AS name, type_commerce AS specialty, description, location, telephone, siret, site_web, horaires_ouverture, photo_url FROM users u JOIN commercant_profiles cp ON u.id = cp.user_id WHERE u.id = $1',
        [professionalId]
      );
    } else {
        return res.status(404).json({ message: 'Profil de ce type de professionnel non géré.' });
    }

    if (profileResult.rows.length === 0) {
      return res.status(404).json({ message: 'Profil du professionnel non trouvé.' });
    }

    // 3. Send unified response
    const professional = {
      ...profileResult.rows[0],
      role: role, // Add role to the response
      isOnline: connectedUsers.has(professionalId.toString())
    };

    res.json(professional);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const getArtisanPortfolio = async (req, res) => {
  try {
    // Validation et parsing sécurisé de l'ID
    const paramValue = req.params.id;
    if (!paramValue || isNaN(paramValue) || parseInt(paramValue) <= 0) {
      return res.status(400).json({ message: 'ID invalide fourni.' });
    }
    
    const artisanId = parseInt(paramValue);
    const result = await pool.query('SELECT * FROM portfolio_items WHERE artisan_id = $1', [artisanId]);
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const getArtisanServices = async (req, res) => {
  try {
    // Validation et parsing sécurisé de l'ID
    const paramValue = req.params.artisanId || req.params.id;
    if (!paramValue || isNaN(paramValue) || parseInt(paramValue) <= 0) {
      return res.status(400).json({ message: 'ID invalide fourni.' });
    }
    
    const artisanId = parseInt(paramValue);
    const result = await pool.query('SELECT * FROM services WHERE artisan_id = $1', [artisanId]);
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};


module.exports = {
  getArtisans,
  getArtisan,
  getArtisanPortfolio,
  getArtisanServices
};
