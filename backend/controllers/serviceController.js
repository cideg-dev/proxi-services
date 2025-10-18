const pool = require('../db.config');

const addService = async (req, res) => {
  const artisanId = parseInt(req.params.artisanId);
  console.log('req.user.user.id', req.user?.user?.id);
  console.log('artisanId', artisanId);
  // Vérifie que l'utilisateur authentifié est bien l'artisan propriétaire
  if (req.user?.user?.id !== artisanId) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  const { name, description, price } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO services (artisan_id, name, description, price) VALUES ($1, $2, $3, $4) RETURNING *',
      [artisanId, name, description, price]
    );
    res.status(201).json({ message: 'Service ajouté avec succès.', service: result.rows[0] });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const updateService = async (req, res) => {
  const { artisanId, serviceId } = req.params;
  if (req.user?.user?.id !== parseInt(artisanId)) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  const { name, description, price } = req.body;

  try {
    const result = await pool.query(
      'UPDATE services SET name = $1, description = $2, price = $3 WHERE id = $4 AND artisan_id = $5 RETURNING *',
      [name, description, price, serviceId, artisanId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Service non trouvé.' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

const deleteService = async (req, res) => {
  const { artisanId, serviceId } = req.params;
  if (req.user?.user?.id !== parseInt(artisanId)) {
    return res.status(403).json({ message: 'Action non autorisée.' });
  }

  try {
    const result = await pool.query('DELETE FROM services WHERE id = $1 AND artisan_id = $2', [serviceId, artisanId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Service non trouvé.' });
    }

    res.json({ message: 'Service supprimé avec succès.' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Erreur du serveur');
  }
};

module.exports = {
  addService,
  updateService,
  deleteService,
};
