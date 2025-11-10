#!/usr/bin/env node

/**
 * Script de test de sécurité
 * Exécute une série de vérifications de sécurité sur l'application
 */

require('dotenv').config();
const { runSecurityCheck } = require('./src/utils/securityCheck');

console.log('🔍 Exécution du script de test de sécurité...\n');

// Exécuter la vérification de sécurité complète
const result = runSecurityCheck();

console.log('\n🏁 Fin du script de test de sécurité');

// Terminer avec un code d'erreur approprié
process.exit(result ? 0 : 1);