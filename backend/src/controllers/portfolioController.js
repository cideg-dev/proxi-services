const sharp = require('sharp');
const path = require('path');
// Utilisation d'un chemin relatif plus explicite pour éviter les problèmes de module
const dbConfigPath = path.join(__dirname, '..', '..', 'db.config');
const pool = require(dbConfigPath);
const fs = require('fs');

const addPortfolioItem = async (req, res) => {
  console.log('addPortfolioItem request body:', req.body);
  console.log('addPortfolioItem request file:', req.file);
  
  try {
    const professionalId = parseInt(req.params.artisanId);
    if (req.user.user.id !== professionalId) {
      return res.status(403).json({ message: 'Action non autorisée.' });
    }

    if (!req.file) {
      return res.status(400).json({ message: 'Image requise.' });
    }

    // Vérification du type de fichier
    if (!req.file.mimetype.startsWith('image/')) {
      return res.status(400).json({ message: 'Type de fichier non supporté. Seules les images sont autorisées.' });
    }

    const { name, description, price } = req.body;

    if (!name || !description) {
      return res.status(400).json({ message: 'Le nom et la description sont requis.' });
    }

  try {
    // Generate a unique filename with .webp extension
    const filename = `portfolio-${professionalId}-${Date.now()}.webp`;
    const outputPath = path.join(__dirname, '..', 'uploads', filename);

    // Process image with sharp: resize, convert to webp, and save
    await sharp(req.file.buffer)
      .resize({ width: 800, withoutEnlargement: true })
      .webp({ quality: 85 })
      .toFile(outputPath);

    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${filename}`;

    const result = await pool.query(
      'INSERT INTO portfolio_items (artisan_id, image_url, name, description, price) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [professionalId, imageUrl, name, description, price || null] // Use price or null if not provided
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const updatePortfolioItem = async (req, res) => {
  const { artisanId: professionalId, portfolioId } = req.params;
  if (req.user.user.id !== parseInt(professionalId)) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  // Vérification du type de fichier si un fichier est fourni
  if (req.file && !req.file.mimetype.startsWith('image/')) {
    return res.status(400).json({ message: 'Type de fichier non supporté. Seules les images sont autorisées.' });
  }

  const { caption } = req.body;
  const imageUrl = req.file ? `${req.protocol}://${req.get('host')}${req.file.path.replace(/\\/g, '/').substring(req.file.path.indexOf('/uploads'))}` : null;

  try {
    const existingItemResult = await pool.query('SELECT * FROM portfolio_items WHERE id = $1 AND artisan_id = $2', [portfolioId, professionalId]);
    if (existingItemResult.rows.length === 0) {
      return res.status(404).json({ message: 'Élément de portfolio non trouvé.' });
    }

    const oldImageUrl = existingItemResult.rows[0].image_url;

    const newImageUrl = imageUrl || oldImageUrl;

    const result = await pool.query(
      'UPDATE portfolio_items SET caption = $1, image_url = $2 WHERE id = $3 AND artisan_id = $4 RETURNING *',
      [caption, newImageUrl, portfolioId, professionalId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Élément de portfolio non trouvé.' });
    }

    if (imageUrl && oldImageUrl) {
      const oldImagePath = path.join(__dirname, '..', oldImageUrl);
      fs.unlink(oldImagePath, (err) => {
        if (err) console.error('Erreur lors de la suppression de l\'ancienne image:', err);
      });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const deletePortfolioItem = async (req, res) => {
  const { artisanId: professionalId, portfolioId } = req.params;
  if (req.user.user.id !== parseInt(professionalId)) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  try {
    const result = await pool.query('DELETE FROM portfolio_items WHERE id = $1 AND artisan_id = $2 RETURNING image_url', [portfolioId, professionalId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Élément de portfolio non trouvé.' });
    }

    const imageUrl = result.rows[0].image_url;
    if (imageUrl) {
      const imagePath = path.join(__dirname, '..', imageUrl);
      fs.unlink(imagePath, (err) => {
        if (err) console.error('Erreur lors de la suppression de l\'image:', err);
      });
    }

    res.json({ message: 'Élément de portfolio supprimé avec succès.' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const getPortfolioItems = async (req, res) => {
  const professionalId = parseInt(req.params.artisanId);

  try {
    const result = await pool.query('SELECT * FROM portfolio_items WHERE artisan_id = $1 ORDER BY id DESC', [professionalId]);
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const getRecentPortfolioItems = async (req, res) => {
  try {
    // This query joins portfolio_items with user profiles to get professional's details
    const result = await pool.query(`
      SELECT 
        p.id, p.artisan_id, p.image_url, p.name, p.description, p.price,
        COALESCE(ap.nom_complet, cp.nom_entreprise) as professional_name,
        COALESCE(ap.photo_url, cp.photo_url) as professional_photo_url
      FROM portfolio_items p
      LEFT JOIN artisan_profiles ap ON p.artisan_id = ap.user_id
      LEFT JOIN commercant_profiles cp ON p.artisan_id = cp.user_id
      ORDER BY p.id DESC
      LIMIT 10
    `);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching recent portfolio items:', err.message);
    res.status(500).send('Erreur du serveur');
  }
};

module.exports = {
  getPortfolioItems,
  getRecentPortfolioItems, // Export the new function
  addPortfolioItem,
  updatePortfolioItem,
  deletePortfolioItem,
};