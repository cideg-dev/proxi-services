const request = require('supertest');
const { app, server } = require('../server');
const pool = require('../db.config');

describe('Authentication API Tests', () => {
  // Clean up users created in each test to ensure test isolation
  afterEach(async () => {
    await pool.query("DELETE FROM users WHERE email LIKE 'auth.test.%%'");
  });

  afterAll(async () => {
    pool.end();
    server.close();
  });

  // Test Case 1: Successful User Registration
  test('should register a new user successfully', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.newuser@example.com', password: 'password123', role: 'client' });

    expect(response.statusCode).toBe(201);
    expect(response.body.message).toBe('Utilisateur enregistré avec succès.');
    expect(response.body.user).toHaveProperty('id');
    expect(response.body.user).toHaveProperty('email', 'auth.test.newuser@example.com');
    expect(response.body.user).toHaveProperty('role', 'client');
    expect(response.body).toHaveProperty('token');
  });

  // Test Case 2: Registration with Existing Email
  test('should NOT register a user with an already existing email', async () => {
    // First, register a user
    await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.existing@example.com', password: 'password123', role: 'client' });

    // Try to register again with the same email
    const response = await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.existing@example.com', password: 'password456', role: 'client' });

    expect(response.statusCode).toBe(409);
    expect(response.body.message).toBe('Cet email est déjà utilisé.');
  });

  // Test Case 3: Successful User Login
  test('should log in an existing user successfully', async () => {
    // First, register a user
    await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.loginuser@example.com', password: 'password123', role: 'client' });

    // Then, try to log in
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'auth.test.loginuser@example.com', password: 'password123' });

    expect(response.statusCode).toBe(200);
    expect(response.body.message).toBe('Connexion réussie.');
    expect(response.body.user).toHaveProperty('id');
    expect(response.body.user).toHaveProperty('email', 'auth.test.loginuser@example.com');
    expect(response.body.user).toHaveProperty('role', 'client');
    expect(response.body).toHaveProperty('token');
  });

  // Test Case 4: Login with Incorrect Password
  test('should NOT log in with an incorrect password', async () => {
    // First, register a user
    await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.wrongpass@example.com', password: 'password123', role: 'client' });

    // Then, try to log in with wrong password
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'auth.test.wrongpass@example.com', password: 'wrongpassword' });

    expect(response.statusCode).toBe(401);
    expect(response.body.message).toBe('Email ou mot de passe incorrect.');
  });

  // Test Case 5: Login with Non-Existent Email
  test('should NOT log in with a non-existent email', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'auth.test.nonexistent@example.com', password: 'password123' });

    expect(response.statusCode).toBe(401);
    expect(response.body.message).toBe('Email ou mot de passe incorrect.');
  });
});