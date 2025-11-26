const request = require('supertest');
const { app, server } = require('../server');
const pool = require('../db.config');

describe('AI Portfolio Generation API', () => {
    let authToken;
    let userId;
    const testUserEmail = `ai.test.artisan@example.com`;
    const testUserPassword = 'password123';

    // Avant tous les tests, créer un utilisateur artisan et se connecter pour obtenir un token
    beforeAll(async () => {
        // Nettoyer au cas où un test précédent aurait échoué
        await pool.query("DELETE FROM users WHERE email = $1", [testUserEmail]);

        // 1. Enregistrer un nouvel artisan
        const registerResponse = await request(app)
            .post('/api/auth/register')
            .send({
                email: testUserEmail,
                password: testUserPassword,
                role: 'artisan',
                // Inclure les champs requis pour le profil d'artisan
                nom_complet: 'Artisan de Test IA',
                specialite: 'Test IA'
            });

        if (registerResponse.statusCode !== 201) {
            console.error('Failed to register test user:', registerResponse.body);
            throw new Error('Setup failed: Could not register test user.');
        }
        
        userId = registerResponse.body.user.id;

        // 2. Se connecter pour obtenir le token
        const loginResponse = await request(app)
            .post('/api/auth/login')
            .send({ email: testUserEmail, password: testUserPassword });

        if (loginResponse.statusCode !== 200) {
            throw new Error('Setup failed: Could not log in to get token.');
        }

        authToken = loginResponse.body.token;
    });

    // Après tous les tests, nettoyer l'utilisateur créé
    afterAll(async () => {
        await pool.query("DELETE FROM users WHERE email = $1", [testUserEmail]);
        pool.end();
        server.close();
    });

    // Le test principal
    test('should generate and save a portfolio for an authenticated artisan', async () => {
        // S'assurer que le token a bien été obtenu
        expect(authToken).toBeDefined();

        const response = await request(app)
            .post('/api/ai/generate-portfolio')
            .set('Authorization', `Bearer ${authToken}`)
            .send({ description: 'Je suis un ébéniste spécialisé dans la restauration de meubles anciens en bois de noyer.' });

        // Vérifier la réponse de l'API
        expect(response.statusCode).toBe(200);
        expect(response.body.message).toBe('Portfolio généré et sauvegardé avec succès !');
        expect(response.body.data).toHaveProperty('bio');
        expect(response.body.data).toHaveProperty('services');
        expect(response.body.data).toHaveProperty('image_prompts');
        expect(response.body.data.services.length).toBeGreaterThan(0);
        expect(response.body.data.image_prompts.length).toBeGreaterThan(0);

        // Vérifier directement en base de données
        // 1. Vérifier la bio (description)
        const profileRes = await pool.query('SELECT description FROM artisan_profiles WHERE user_id = $1', [userId]);
        expect(profileRes.rows[0].description).toBe(response.body.data.bio);

        // 2. Vérifier les services
        const servicesRes = await pool.query('SELECT name FROM services WHERE artisan_id = $1', [userId]);
        expect(servicesRes.rows.length).toBe(response.body.data.services.length);

        // 3. Vérifier les items du portfolio (images)
        const portfolioRes = await pool.query('SELECT image_url, caption FROM portfolio_items WHERE artisan_id = $1', [userId]);
        expect(portfolioRes.rows.length).toBe(response.body.data.image_prompts.length);
        expect(portfolioRes.rows[0].caption).toBe(response.body.data.image_prompts[0]);
    }, 20000); // Augmenter le timeout à 20s pour laisser le temps à l'API Gemini de répondre
});
