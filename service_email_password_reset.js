const nodemailer = require('nodemailer');
const validator = require('validator');
const logger = require('./logger');

const sendPasswordResetEmail = async (to, token) => {
  // Validation de l'adresse e-mail
  if (!to || !validator.isEmail(to)) {
    logger.error('Adresse e-mail invalide pour la réinitialisation du mot de passe:', to);
    return;
  }

  // Validation du token
  if (!token || typeof token !== 'string' || token.length < 20) {
    logger.error('Token de réinitialisation invalide');
    return;
  }

  // Création sécurisée du transporteur
  const transporter = nodemailer.createTransporter({
    host: process.env.SMTP_HOST || 'localhost',
    port: parseInt(process.env.SMTP_PORT) || 587,
    secure: parseInt(process.env.SMTP_PORT) === 465, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
    // Limites pour la sécurité
    rateLimiter: true,
    maxConnections: 1,
    maxMessages: 10
  });

  // Validation en amont du transporteur
  try {
    await transporter.verify();
  } catch (error) {
    logger.error('Erreur de configuration du transporteur e-mail:', error);
    return;
  }

  // Construction sécurisée de l'URL de réinitialisation
  let resetUrl;
  if (process.env.NODE_ENV === 'production') {
    resetUrl = `${process.env.FRONTEND_URL || 'https://proxi-services.com'}/reset-password?token=${encodeURIComponent(token)}`;
  } else {
    resetUrl = `http://localhost:5173/reset-password?token=${encodeURIComponent(token)}`;
  }

  const mailOptions = {
    from: {
      name: 'Proxi-Services',
      address: process.env.SMTP_USER || 'noreply@proxiservices.com'
    },
    to: validator.escape(to), // Échapper l'adresse e-mail pour éviter les attaques d'injection
    subject: 'Réinitialisation de votre mot de passe',
    html: `
      <p>Bonjour,</p>
      <p>Vous avez demandé une réinitialisation de votre mot de passe.</p>
      <p>Cliquez sur le lien ci-dessous pour choisir un nouveau mot de passe. Ce lien expirera dans une heure.</p>
      <a href="${validator.escape(resetUrl)}">${validator.escape(resetUrl)}</a>
      <p>Si vous n'êtes pas à l'origine de cette demande, veuillez ignorer cet e-mail.</p>
      <p>Merci,</p>
      <p>L'équipe Proxi-Services</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    logger.info('E-mail de réinitialisation de mot de passe envoyé avec succès à:', to);
  } catch (error) {
    logger.error('Erreur lors de l\'envoi de l\'e-mail de réinitialisation de mot de passe:', error);
    // Nous ne renvoyons pas l'erreur à l'utilisateur pour des raisons de sécurité
    // L'utilisateur ne doit pas savoir si un e-mail existe ou non dans le système
  }
};

module.exports = { sendPasswordResetEmail };
