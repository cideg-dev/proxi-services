// backend/src/services/envValidationService.js
require('dotenv').config();

/**
 * Service de validation des variables d'environnement critiques
 */
class EnvValidationService {
  /**
   * Liste des variables d'environnement requises
   * @returns {Array} Liste des noms de variables requises
   */
  static getRequiredVariables() {
    return [
      'JWT_SECRET',
      'JWT_REFRESH_SECRET',
      'DATABASE_URL',
      'FRONTEND_URL',
      'ENCRYPTION_KEY'
    ];
  }

  /**
   * Liste des variables d'environnement optionnelles mais recommandées
   * @returns {Array} Liste des noms de variables optionnelles
   */
  static getRecommendedVariables() {
    return [
      'REDIS_HOST',
      'REDIS_PORT',
      'REDIS_PASSWORD',
      'SMTP_HOST',
      'SMTP_PORT',
      'SMTP_USER',
      'SMTP_PASS',
      'LOG_LEVEL'
    ];
  }

  /**
   * Valide toutes les variables d'environnement requises
   * @returns {Object} Résultat de la validation
   */
  static validateAll() {
    const requiredVars = this.getRequiredVariables();
    const recommendedVars = this.getRecommendedVariables();
    
    const missingRequired = [];
    const invalidRequired = [];
    const missingRecommended = [];
    
    // Vérifier les variables requises
    for (const varName of requiredVars) {
      const value = process.env[varName];
      if (!value) {
        missingRequired.push(varName);
      } else if (varName === 'ENCRYPTION_KEY' && value.length < 64) { // 32 octets en hex
        invalidRequired.push({
          name: varName,
          issue: 'La clé de chiffrement doit être d\'au moins 32 octets (64 caractères hex)'
        });
      } else if ((varName === 'JWT_SECRET' || varName === 'JWT_REFRESH_SECRET') && value.length < 32) {
        invalidRequired.push({
          name: varName,
          issue: 'La clé secrète JWT doit être d\'au moins 32 caractères'
        });
      }
    }
    
    // Vérifier les variables recommandées
    for (const varName of recommendedVars) {
      const value = process.env[varName];
      if (!value) {
        missingRecommended.push(varName);
      }
    }
    
    return {
      valid: missingRequired.length === 0 && invalidRequired.length === 0,
      missingRequired,
      invalidRequired,
      missingRecommended,
      totalMissing: missingRequired.length + missingRecommended.length,
      totalInvalid: invalidRequired.length
    };
  }

  /**
   * Affiche un rapport de validation des variables d'environnement
   * @param {Object} results Résultats de la validation
   */
  static printValidationReport(results) {
    console.log('\n=== Rapport de validation des variables d\'environnement ===\n');
    
    if (results.missingRequired.length > 0) {
      console.log('❌ Variables requises manquantes:');
      results.missingRequired.forEach(varName => {
        console.log(`  - ${varName}`);
      });
      console.log();
    }
    
    if (results.invalidRequired.length > 0) {
      console.log('❌ Variables requises invalides:');
      results.invalidRequired.forEach(item => {
        console.log(`  - ${item.name}: ${item.issue}`);
      });
      console.log();
    }
    
    if (results.missingRecommended.length > 0) {
      console.log('⚠️  Variables optionnelles manquantes (recommandées):');
      results.missingRecommended.forEach(varName => {
        console.log(`  - ${varName}`);
      });
      console.log();
    }
    
    if (results.valid) {
      console.log('✅ Toutes les variables requises sont correctement configurées!\n');
    } else {
      console.log(`❌ ${results.totalMissing} variables manquantes, ${results.totalInvalid} invalides\n`);
    }
  }

  /**
   * Valide et quitte l'application si des variables critiques sont manquantes
   */
  static validateAndExitIfCritical() {
    const results = this.validateAll();
    
    if (!results.valid) {
      this.printValidationReport(results);
      
      // Vérifier s'il y a des erreurs critiques
      const hasCriticalErrors = results.missingRequired.length > 0 || results.invalidRequired.length > 0;
      
      if (hasCriticalErrors) {
        console.error('ERREUR: Des variables d\'environnement critiques sont manquantes ou invalides.');
        console.error('L\'application ne peut pas démarrer.');
        process.exit(1);
      }
    } else {
      console.log('✅ Toutes les variables d\'environnement requises sont correctement configurées.');
    }
  }
}

module.exports = EnvValidationService;