const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/db.config');

// Tests pour le contrôleur API
describe('API Controller Tests', () => {
  // Test de la route de santé
  describe('GET /', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('API is running');
    });
  });

  // Test de la route de version
  describe('GET /api/system/version', () => {
    it('should return API version', async () => {
      const response = await request(app).get('/api/system/version');
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.version).toBeDefined();
    });
  });

  // Test de la route pour obtenir les artisans
  describe('GET /api/artisans', () => {
    it('should return artisans with pagination', async () => {
      const response = await request(app)
        .get('/api/artisans')
        .query({ page: 1, limit: 10 });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.pagination).toBeDefined();
    });
  });

  // Test de la route pour obtenir un artisan spécifique
  describe('GET /api/artisans/:id', () => {
    it('should return a specific artisan by ID', async () => {
      // Remplacer avec un ID existant dans votre base de données pour le test réel
      const response = await request(app).get('/api/artisans/1');
      
      // Le test exact dépendra de la structure de votre base de données
      if (response.status === 404) {
        // Cet artisan particulier n'existe pas, ce qui est acceptable
        expect(response.status).toBe(404);
      } else {
        expect(response.status).toBe(200);
        expect(response.body.success).toBe(true);
        expect(response.body.data).toBeDefined();
      }
    });
  });
});

// Tests pour les routes d'authentification
describe('Auth Routes Tests', () => {
  describe('POST /api/auth/register', () => {
    it('should not register a user without required fields', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({});
      
      expect(response.status).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should not login with invalid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'invalid@example.com',
          password: 'wrongpassword'
        });
      
      expect(response.status).toBe(401);
    });
  });
});

// Tests pour les routes de profil
describe('Profile Routes Tests', () => {
  // Ces tests nécessiteront une authentification
  describe('GET /api/profile', () => {
    it('should require authentication', async () => {
      const response = await request(app).get('/api/profile');
      expect(response.status).toBe(401); // Non authentifié
    });
  });
});

// Tests de performance
describe('Performance Tests', () => {
  describe('GET /api/performance', () => {
    it('should return performance metrics', async () => {
      const start = Date.now();
      const response = await request(app).get('/api/performance');
      const duration = Date.now() - start;
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(typeof response.body.responseTime).toBe('string');
      // Le test de performance est passé si le temps est raisonnable
      expect(duration).toBeLessThan(1000); // Moins de 1 seconde
    });
  });
});