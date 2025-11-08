// Contrôleur pour les routes générales de l'application

const { version } = require('../../package.json');

exports.healthCheck = (req, res) => {
  res.send('Le serveur backend Proxi-Services fonctionne !');
};

exports.getVersion = (req, res) => {
  res.json({ latest_version: version });
};