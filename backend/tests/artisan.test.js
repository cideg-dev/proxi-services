const request = require('supertest');
const { app, server } = require('../server'); // Assurez-vous que server est exporté
const pool = require('../db.config');

describe('Artisan API Endpoints', () => {

  // Fermer la connexion à la base de données et le serveur après tous les tests
  afterAll(async () => {
    await pool.end();
    server.close();
  });

  describe('GET /api/artisans', () => {
    it('should return a list of professionals', async () => {
      const response = await request(app)
        .get('/api/artisans')
        .expect(200)
        .expect('Content-Type', /json/);

      // S'attendre à ce que le corps de la réponse soit un tableau
      expect(Array.isArray(response.body)).toBe(true);

      // Optionnel : vérifier la structure du premier élément s'il y en a un
      if (response.body.length > 0) {
        const professional = response.body[0];
        expect(professional).toHaveProperty('id');
        expect(professional).toHaveProperty('name');
        expect(professional).toHaveProperty('specialty');
        expect(professional).toHaveProperty('role');
        expect(professional).toHaveProperty('isOnline');
      }
    });
  });

});
