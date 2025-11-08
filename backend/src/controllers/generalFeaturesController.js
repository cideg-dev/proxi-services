// Contrôleur pour les fonctionnalités générales de l'application

const pool = require('../../db.config');

// GET /api/users/all - Récupérer tous les utilisateurs (simplifié)
const getAllUsers = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        u.id,
        u.email,
        u.role,
        u.created_at,
        u.last_seen,
        COALESCE(ap.nom_complet, cp.nom_complet, comm.nom_entreprise) AS nom
      FROM users u
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN commercant_profiles comm ON u.id = comm.user_id
      ORDER BY u.created_at DESC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Erreur lors de la récupération des utilisateurs:', error);
    res.status(500).json({ message: "Erreur serveur lors de la récupération des utilisateurs" });
  }
};

// GET /api/professionals/featured - Récupérer les professionnels mis en avant
const getFeaturedProfessionals = async (req, res) => {
  try {
    // Cette requête récupère les artisans et commercants avec leurs profils
    const result = await pool.query(`
      SELECT
        u.id,
        u.role,
        COALESCE(ap.nom_complet, comm.nom_entreprise) AS nom,
        COALESCE(ap.specialite, comm.type_commerce) AS specialite,
        COALESCE(ap.description, comm.description) AS description,
        COALESCE(ap.photo_url, comm.photo_url) AS photo_url,
        COALESCE(ap.location, comm.location) AS location,
        ap.avis_moyen AS rating
      FROM users u
      LEFT JOIN artisan_profiles ap ON u.id = ap.user_id AND u.role = 'artisan'
      LEFT JOIN commercant_profiles comm ON u.id = comm.user_id AND u.role = 'commercant'
      WHERE u.role IN ('artisan', 'commercant')
      AND (ap.afficher_public IS NULL OR ap.afficher_public = true)  -- Supposons qu'il y ait un champ pour montrer publiquement
      AND (comm.afficher_public IS NULL OR comm.afficher_public = true)
      ORDER BY ap.avis_moyen DESC NULLS LAST  -- Classer par note moyenne, nulls en dernier
      LIMIT 10
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Erreur lors de la récupération des professionnels mis en avant:', error);
    res.status(500).json({ message: "Erreur serveur lors de la récupération des professionnels mis en avant" });
  }
};

// GET /api/professional/demandes - Récupérer les demandes pour un professionnel
const getProfessionalDemandes = async (req, res) => {
  if (!req.user || !['artisan', 'commercant'].includes(req.user.user.role)) {
    return res.status(403).json({ message: "Accès refusé. Rôle non autorisé." });
  }
  
  const professionalId = req.user.user.id;

  try {
    const result = await pool.query(`
      SELECT 
        d.*,
        c.nom_complet AS client_name
      FROM demandes d
      JOIN client_profiles c ON d.client_id = c.user_id
      WHERE d.artisan_id = $1
      ORDER BY d.created_at DESC
    `, [professionalId]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Erreur lors de la récupération des demandes:', error);
    res.status(500).json({ message: "Erreur serveur lors de la récupération des demandes" });
  }
};

module.exports = {
  getAllUsers,
  getFeaturedProfessionals,
  getProfessionalDemandes
};