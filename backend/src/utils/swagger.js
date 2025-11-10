const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Proxi-Services API',
      version: '1.0.0',
      description: 'API pour la plateforme Proxi-Services de mise en relation entre clients, artisans et commerçants',
      contact: {
        name: 'Proxi-Services Support',
        email: 'support@proxi-services.com',
      },
    },
    servers: [
      {
        url: process.env.FRONTEND_URL || 'http://localhost:10000',
        description: 'Serveur de développement',
      },
    ],
  },
  apis: [
    './src/routes/*.js', 
    './src/controllers/*.js', 
    './src/controllers/authController.js',
    './src/controllers/artisanController.js',
    './src/controllers/reviewController.js'
  ], // Chemins vers les fichiers contenant les annotations JSDoc
};

const specs = swaggerJsdoc(options);

module.exports = specs;