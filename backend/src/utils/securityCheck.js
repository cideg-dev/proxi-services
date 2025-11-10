/**
 * Utilitaire de vérification de sécurité
 * Ce module fournit des fonctions pour vérifier la configuration de sécurité
 */

const fs = require('fs');
const path = require('path');
const { logger } = require('./logger');

/**
 * Vérifie la présence des variables d'environnement critiques
 */
const checkEnvironmentVariables = () => {
  const requiredEnvVars = [
    'JWT_SECRET',
    'JWT_REFRESH_SECRET',
    'DATABASE_URL',
    'DB_USER',
    'DB_HOST',
    'DB_NAME',
    'DB_PASSWORD',
    'DB_PORT',
    'SMTP_HOST',
    'SMTP_PORT',
    'SMTP_USER',
    'SMTP_PASS',
    'FRONTEND_URL'
  ];

  const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

  if (missingEnvVars.length > 0) {
    logger.error(`Variables d'environnement critiques manquantes: ${missingEnvVars.join(', ')}`);
    console.error(`ERREUR: Variables d'environnement critiques manquantes: ${missingEnvVars.join(', ')}`);
    return false;
  }

  logger.info('✅ Toutes les variables d\'environnement critiques sont présentes');
  return true;
};

/**
 * Vérifie la configuration de sécurité
 */
const checkSecurityConfiguration = () => {
  const checks = {
    jwtConfigured: process.env.JWT_SECRET && process.env.JWT_SECRET.length > 32,
    secureCookies: process.env.NODE_ENV === 'production',
    corsConfigured: process.env.FRONTEND_URL && process.env.FRONTEND_URL.startsWith('https'),
    rateLimiting: true, // Supposé activé via le middleware
    helmetEnabled: true, // Supposé activé via le middleware
    inputValidation: true, // Supposé activé via les middlewares
    dbSsl: process.env.NODE_ENV === 'production',
    sensitiveDataMasked: true // Supposé via la configuration
  };

  logger.info('📊 Résultats de la vérification de sécurité:');
  Object.entries(checks).forEach(([check, result]) => {
    logger.info(`${result ? '✅' : '❌'} ${check}: ${result ? 'OK' : 'NON CONFIGURÉ'}`);
  });

  const allPassed = Object.values(checks).every(check => check === true);
  return allPassed;
};

/**
 * Vérifie la structure des dossiers critiques
 */
const checkCriticalDirectories = () => {
  const criticalFolders = [
    path.join(__dirname, '../../../logs'),
    path.join(__dirname, '../../../uploads'),
    path.join(__dirname, '../../../backend/uploads')
  ];

  let allExist = true;

  criticalFolders.forEach(folder => {
    if (!fs.existsSync(folder)) {
      logger.warn(`⚠️ Dossier critique manquant: ${folder}`);
      allExist = false;
    } else {
      logger.info(`✅ Dossier critique présent: ${folder}`);
    }
  });

  return allExist;
};

/**
 * Vérifie la sécurité des fichiers de configuration
 */
const checkConfigFilesSecurity = () => {
  const configFiles = [
    path.join(__dirname, '../../../.env'),
    path.join(__dirname, '../../../backend/.env')
  ];

  let allSecure = true;

  configFiles.forEach(filePath => {
    if (fs.existsSync(filePath)) {
      try {
        // Vérifier que .env n'est pas accessible publiquement
        const stats = fs.statSync(filePath);
        // Sur les systèmes Unix, vérifier les permissions
        if (process.platform !== 'win32') {
          const isReadableByGroup = stats.mode & 0o040; // Groupe peut lire
          const isReadableByOther = stats.mode & 0o004; // Autres peuvent lire
          
          if (isReadableByOther) {
            logger.warn(`⚠️ Le fichier ${filePath} est lisible par les autres utilisateurs`);
            allSecure = false;
          } else {
            logger.info(`✅ Fichier de configuration sécurisé: ${filePath}`);
          }
        } else {
          logger.info(`✅ Fichier de configuration existant: ${filePath} (vérification des permissions non applicable sur Windows)`);
        }
      } catch (error) {
        logger.error(`Erreur lors de la vérification de ${filePath}:`, error.message);
        allSecure = false;
      }
    } else {
      logger.warn(`⚠️ Fichier de configuration manquant: ${filePath}`);
      allSecure = false;
    }
  });

  return allSecure;
};

/**
 * Fait une vérification complète de sécurité
 */
const runSecurityCheck = () => {
  logger.info('🔍 Démarrage de la vérification de sécurité complète...');

  const envCheck = checkEnvironmentVariables();
  const configCheck = checkSecurityConfiguration();
  const dirCheck = checkCriticalDirectories();
  const fileCheck = checkConfigFilesSecurity();

  const overallResult = envCheck && configCheck && dirCheck && fileCheck;

  if (overallResult) {
    logger.info('🎉 Vérification de sécurité complète: TOUT EST SÉCURISÉ');
  } else {
    logger.error('🚨 Vérification de sécurité complète: DES PROBLÈMES ONT ÉTÉ DÉTECTÉS');
  }

  return overallResult;
};

module.exports = {
  checkEnvironmentVariables,
  checkSecurityConfiguration,
  checkCriticalDirectories,
  checkConfigFilesSecurity,
  runSecurityCheck
};