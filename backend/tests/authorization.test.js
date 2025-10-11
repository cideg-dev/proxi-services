const request = require('supertest');
const { app, server } = require('../server');
const pool = require('../db.config');

describe('Authorization Middleware Tests', () => {
  let clientToken, artisanToken, otherArtisanToken, adminToken; // Added adminToken
  let artisanId, clientId, otherArtisanId, adminId; // Added adminId

  beforeAll(async () => {
    // Clean up previous test users if any
    await pool.query("DELETE FROM users WHERE email LIKE 'auth.test.%%'");

    // Create a client user
    const clientRes = await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.client@example.com', password: 'password123', role: 'client' });
    clientToken = clientRes.body.token;
    clientId = clientRes.body.user.id;

    // Create an artisan user
    const artisanRes = await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.artisan@example.com', password: 'password123', role: 'artisan' });
    artisanToken = artisanRes.body.token;
    artisanId = artisanRes.body.user.id;

    // Create another artisan user
    const otherArtisanRes = await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.otherartisan@example.com', password: 'password123', role: 'artisan' });
    otherArtisanToken = otherArtisanRes.body.token;
    otherArtisanId = otherArtisanRes.body.user.id;

    // Create an admin user
    const adminRes = await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.admin@example.com', password: 'password123', role: 'admin' });
    adminToken = adminRes.body.token;
    adminId = adminRes.body.user.id;

    // Create profiles for artisans to enable functionalities like adding services
    await pool.query('INSERT INTO artisan_profiles (user_id, nom_complet, specialite, location) VALUES ($1, $2, $3, $4) ON CONFLICT (user_id) DO NOTHING', [artisanId, 'Test Artisan', 'Plomberie', 'Paris']);
    await pool.query('INSERT INTO artisan_profiles (user_id, nom_complet, specialite, location) VALUES ($1, $2, $3, $4) ON CONFLICT (user_id) DO NOTHING', [otherArtisanId, 'Other Artisan', 'Electricite', 'Lyon']);
  });

  // Test Case 1: Client trying to add a service to an artisan's profile
  test('A client should NOT be able to add a service to an artisan\'s profile', async () => {
    const response = await request(app)
      .post(`/api/artisans/${artisanId}/services`)
      .set('Authorization', `Bearer ${clientToken}`)
      .send({ name: 'Leaky Faucet Repair', description: 'Fixing leaky faucets', price: '50' });
    
    expect(response.statusCode).toBe(403);
    expect(response.body.message).toBe('Action non autorisée.');
  });

  // Test Case 2: Artisan trying to modify another artisan's services
  test('An artisan should NOT be able to add a service to another artisan\'s profile', async () => {
    const response = await request(app)
      .post(`/api/artisans/${artisanId}/services`)
      .set('Authorization', `Bearer ${otherArtisanToken}`)
      .send({ name: 'Unauthorized Service', description: 'This should not be added', price: '100' });

    expect(response.statusCode).toBe(403);
    expect(response.body.message).toBe('Action non autorisée.');
  });

  // Test Case 3: Client trying to access an artisan's list of demands
  test('A client should NOT be able to access the list of demands for an artisan', async () => {
    const response = await request(app)
      .get('/api/artisan/demandes')
      .set('Authorization', `Bearer ${clientToken}`);

    expect(response.statusCode).toBe(403);
    expect(response.body.message).toBe('Action non autorisée pour votre rôle.');
  });

  // Test Case 4: An artisan should be able to add a service to their own profile
  test('An artisan SHOULD be able to add a service to their own profile', async () => {
    const response = await request(app)
      .post(`/api/artisans/${artisanId}/services`)
      .set('Authorization', `Bearer ${artisanToken}`)
      .send({ name: 'Legit Service', description: 'A service added by the owner', price: '120' });

    expect(response.statusCode).toBe(201);
    expect(response.body.message).toBe('Service ajouté avec succès.');
  });

  // NEW ADMIN TESTS
  describe('Admin User Management Authorization', () => {
    // Test GET /api/admin/users
    test('A client should NOT be able to list all users', async () => {
      const response = await request(app)
        .get('/api/admin/users')
        .set('Authorization', `Bearer ${clientToken}`);
      expect(response.statusCode).toBe(403);
      expect(response.body.message).toBe('Action non autorisée pour votre rôle.');
    });

    test('An admin SHOULD be able to list all users', async () => {
      const response = await request(app)
        .get('/api/admin/users')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(response.statusCode).toBe(200);
      expect(response.body.users).toBeInstanceOf(Array);
      expect(response.body.users.length).toBeGreaterThan(0);
    });

    // Test GET /api/admin/users/:id
    test('A client should NOT be able to get details of a user', async () => {
      const response = await request(app)
        .get(`/api/admin/users/${artisanId}`)
        .set('Authorization', `Bearer ${clientToken}`);
      expect(response.statusCode).toBe(403);
      expect(response.body.message).toBe('Action non autorisée pour votre rôle.');
    });

    test('An admin SHOULD be able to get details of a user', async () => {
      const response = await request(app)
        .get(`/api/admin/users/${artisanId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(response.statusCode).toBe(200);
      expect(response.body.id).toBe(artisanId);
      expect(response.body.role).toBe('artisan');
    });

    // Test PUT /api/admin/users/:id/block
    test('A client should NOT be able to block a user', async () => {
      const response = await request(app)
        .put(`/api/admin/users/${artisanId}/block`)
        .set('Authorization', `Bearer ${clientToken}`)
        .send({ isBlocked: true });
      expect(response.statusCode).toBe(403);
      expect(response.body.message).toBe('Action non autorisée pour votre rôle.');
    });

    test('An admin SHOULD be able to block a user', async () => {
      const response = await request(app)
        .put(`/api/admin/users/${artisanId}/block`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ isBlocked: true });
      expect(response.statusCode).toBe(200);
      expect(response.body.user.is_blocked).toBe(true);
      // Unblock for subsequent tests
      await request(app)
        .put(`/api/admin/users/${artisanId}/block`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ isBlocked: false });
    });

    // Test DELETE /api/admin/users/:id
    test('A client should NOT be able to delete a user', async () => {
      const response = await request(app)
        .delete(`/api/admin/users/${otherArtisanId}`)
        .set('Authorization', `Bearer ${clientToken}`);
      expect(response.statusCode).toBe(403);
      expect(response.body.message).toBe('Action non autorisée pour votre rôle.');
    });

    test('An admin SHOULD be able to delete a user', async () => {
      // Create a temporary user to delete
      const tempUserRes = await request(app)
        .post('/api/auth/register')
        .send({ email: 'auth.test.todelete@example.com', password: 'password123', role: 'client' });
      const tempUserId = tempUserRes.body.user.id;

      const response = await request(app)
        .delete(`/api/admin/users/${tempUserId}`)
        .set('Authorization', `Bearer ${adminToken}`);
      expect(response.statusCode).toBe(200);
      expect(response.body.message).toBe('Utilisateur supprimé avec succès.');
    });
  });


  // Test case: A client should NOT be able to access an artisan-only route (moved from auth.test.js)
  test('should return 403 Forbidden when a client tries to access an artisan route', async () => {
    const response = await request(app)
      .post(`/api/artisans/${artisanId}/services`) // This route requires 'artisan' role
      .set('Authorization', `Bearer ${clientToken}`)
      .send({ name: 'Test Service', description: 'A service that should not be created', price: '100' });
    
    // Expect a 403 Forbidden status
    expect(response.statusCode).toBe(403);
    expect(response.body.message).toBe('Action non autorisée pour votre rôle.');
  });

  afterAll(async () => {
    // Clean up all test users
    await pool.query("DELETE FROM users WHERE email LIKE 'auth.test.%%'");
    pool.end();
    server.close();
  });
});
