const request = require('supertest');
const { app, server } = require('../server');

async function run() {
  try {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ email: 'auth.test.admin@example.com', password: 'password123', role: 'admin' });
    console.log('Status:', res.statusCode);
    console.log('Body:', res.body);
  } catch (e) {
    console.error('Error during debug request:', e);
  } finally {
    server.close();
  }
}

run();