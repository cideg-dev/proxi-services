const nodemailer = require('nodemailer');
const logger = require('./logger');

const sendPasswordResetEmail = async (to, token) => {
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_PORT === 465, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  const resetUrl = `http://localhost:5173/reset-password?token=${token}`;

  const mailOptions = {
    from: `"Proxi-Services" <${process.env.SMTP_USER}>`,
    to,
    subject: 'Réinitialisation de votre mot de passe',
    html: `
      <p>Bonjour,</p>
      <p>Vous avez demandé une réinitialisation de votre mot de passe.</p>
      <p>Cliquez sur le lien ci-dessous pour choisir un nouveau mot de passe. Ce lien expirera dans une heure.</p>
      <a href="${resetUrl}">${resetUrl}</a>
      <p>Si vous n'êtes pas à l'origine de cette demande, veuillez ignorer cet e-mail.</p>
      <p>Merci,</p>
      <p>L'équipe Proxi-Services</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    logger.info('Password reset email sent successfully to:', to);
  } catch (error) {
    logger.error('Error sending password reset email:', error);
    // We don't throw the error to the user, for security reasons
    // The user should not know if an email exists in the system or not
  }
};

module.exports = { sendPasswordResetEmail };
