// Service d'email pour les notifications

const sendNotificationEmail = async (to, subject, text) => {
  // Fonction pour envoyer des emails de notification
  // À implémenter selon les besoins (Nodemailer, SendGrid, etc.)
  console.log(`Envoi d'email à ${to} avec sujet: ${subject}`);
  console.log(`Contenu: ${text}`);
  // Implémentation réelle à ajouter selon les préférences d'email
};

module.exports = {
  sendNotificationEmail
};