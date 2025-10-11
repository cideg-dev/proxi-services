const sharp = require('sharp');
const pool = require('../db.config');
const fs = require('fs');
const path = require('path');

const addPortfolioItem = async (req, res) => {
  const artisanId = parseInt(req.params.artisanId);
  if (req.user.id !== artisanId) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  if (!req.file) {
    return res.status(400).json({ message: 'Image requise.' });
  }

  const { caption } = req.body;

  try {
    // Generate a unique filename with .webp extension
    const filename = `portfolio-${artisanId}-${Date.now()}.webp`;
    const outputPath = path.join(__dirname, '..', 'uploads', filename);

    // Process image with sharp: resize, convert to webp, and save
    await sharp(req.file.buffer)
      .resize({ width: 600, withoutEnlargement: true })
      .webp({ quality: 80 })
      .toFile(outputPath);

    const imageUrl = `/uploads/${filename}`;

    const result = await pool.query(
      'INSERT INTO portfolio_items (artisan_id, image_url, caption) VALUES ($1, $2, $3) RETURNING *',
      [artisanId, imageUrl, caption]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const updatePortfolioItem = async (req, res) => {
  const { artisanId, portfolioId } = req.params;
  if (req.user.id !== parseInt(artisanId)) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  const { caption } = req.body;
  const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

  try {
    const existingItemResult = await pool.query('SELECT * FROM portfolio_items WHERE id = $1 AND artisan_id = $2', [portfolioId, artisanId]);
    if (existingItemResult.rows.length === 0) {
      return res.status(404).json({ message: 'Élément de portfolio non trouvé.' });
    }

    const oldImageUrl = existingItemResult.rows[0].image_url;

    const newImageUrl = imageUrl || oldImageUrl;

    const result = await pool.query(
      'UPDATE portfolio_items SET caption = $1, image_url = $2 WHERE id = $3 AND artisan_id = $4 RETURNING *',
      [caption, newImageUrl, portfolioId, artisanId]
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
  const { artisanId, portfolioId } = req.params;
  if (req.user.id !== parseInt(artisanId)) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  try {
    const result = await pool.query('DELETE FROM portfolio_items WHERE id = $1 AND artisan_id = $2 RETURNING image_url', [portfolioId, artisanId]);

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

module.exports = {
  addPortfolioItem,
  updatePortfolioItem,
  deletePortfolioItem,
};
