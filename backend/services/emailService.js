const nodemailer = require('nodemailer');
const logger = require('./logger');

const sendNotificationEmail = async ({ to, subject, html }) => {
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_PORT == 465, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  const mailOptions = {
    from: `"Proxi-Services" <${process.env.SMTP_USER}>`,
    to,
    subject,
    html,
  };

  try {
    await transporter.sendMail(mailOptions);
    logger.info(`Notification email sent successfully to: ${to} with subject: ${subject}`);
  } catch (error) {
    logger.error(`Error sending notification email to: ${to}`, error);
    // Do not rethrow, to avoid leaking information.
  }
};

const sendPasswordResetEmail = async (to, token) => {
  const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:5173'}/reset-password?token=${token}`;
  const subject = 'Réinitialisation de votre mot de passe';
  const html = `
      <p>Bonjour,</p>
      <p>Vous avez demandé une réinitialisation de votre mot de passe.</p>
      <p>Cliquez sur le lien ci-dessous pour choisir un nouveau mot de passe. Ce lien expirera dans une heure.</p>
      <a href="${resetUrl}">${resetUrl}</a>
      <p>Si vous n'êtes pas à l'origine de cette demande, veuillez ignorer cet e-mail.</p>
      <p>Merci,</p>
      <p>L'équipe Proxi-Services</p>
    `;

  await sendNotificationEmail({ to, subject, html });
};

module.exports = { sendPasswordResetEmail, sendNotificationEmail };
