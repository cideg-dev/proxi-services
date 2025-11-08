// Service pour les fonctionnalités générales

// Fonction pour calculer la distance entre deux points (Haversine)
function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Rayon de la Terre en kilomètres
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance en km
  return distance;
}

// Fonction pour logger les actions d'audit
async function logAuditAction(pool, userId, actionType, entityType, entityId, details) {
  try {
    await pool.query(
      `INSERT INTO audit_logs (user_id, action_type, entity_type, entity_id, details)
       VALUES ($1, $2, $3, $4, $5)`,
      [userId, actionType, entityType, entityId, details]
    );
  } catch (error) {
    console.error('Erreur lors de la journalisation de l\'action d\'audit :', { error: error.message });
  }
}

module.exports = {
  haversineDistance,
  logAuditAction
};