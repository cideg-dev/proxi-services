// Ce script est un test manuel pour la fonctionnalité de génération de portfolio par IA.
// Il ne dépend pas de Jest et peut être exécuté directement avec Node.js.

const axios = require('axios');
const { app, server } = require('../server'); // Importe l'app et le serveur

const PORT = 3001; // Utiliser un port différent pour éviter les conflits
const API_URL = `http://localhost:${PORT}`;

const testUser = {
    email: `manual.ai.test.${Date.now()}@example.com`,
    password: 'password123',
    role: 'artisan',
    nom_complet: 'Artisan Test Manuel',
    specialite: 'Tests Manuels'
};

let authToken;
let userId;

const runTest = async () => {
    try {
        console.log('--- Démarrage du test manuel ---');

        // 1. Enregistrer un nouvel artisan
        console.log('1. Enregistrement de l\'utilisateur artisan...');
        const registerRes = await axios.post(`${API_URL}/api/auth/register`, testUser);
        if (registerRes.status !== 201) {
            throw new Error(`Échec de l\'enregistrement: ${registerRes.data}`);
        }
        userId = registerRes.data.user.id;
        console.log(`Utilisateur ${userId} créé.`);

        // 2. Se connecter pour obtenir le token
        console.log('2. Connexion pour obtenir le token...');
        const loginRes = await axios.post(`${API_URL}/api/auth/login`, {
            email: testUser.email,
            password: testUser.password
        });
        if (loginRes.status !== 200) {
            throw new Error(`Échec de la connexion: ${loginRes.data}`);
        }
        authToken = loginRes.data.token;
        console.log('Token obtenu avec succès.');

        // 3. Appeler la génération de portfolio
        console.log('3. Appel de la génération de portfolio par IA...');
        const aiRes = await axios.post(`${API_URL}/api/ai/generate-portfolio`,
            { description: 'Je suis un forgeron qui crée des couteaux de cuisine artisanaux.' },
            { headers: { Authorization: `Bearer ${authToken}` } }
        );

        if (aiRes.status !== 200) {
            throw new Error(`Échec de la génération IA: ${aiRes.data}`);
        }

        console.log('\n--- ✅ SUCCÈS DU TEST ---');
        console.log('Réponse de l\'API de génération :');
        console.log(aiRes.data);

    } catch (error) {
        console.error('\n--- ❌ ÉCHEC DU TEST ---');
        if (error.response) {
            console.error('Erreur de réponse de l\'API:', error.response.data);
        } else {
            console.error('Erreur:', error.message);
        }
    } finally {
        // 4. Nettoyage et arrêt
        console.log('\n4. Nettoyage de l\'utilisateur de test...');
        const pool = require('../db.config');
        try {
            await pool.query("DELETE FROM users WHERE email = $1", [testUser.email]);
            console.log('Utilisateur de test supprimé.');
        } catch (dbError) {
            console.error('Erreur lors du nettoyage de la base de données:', dbError.message);
        }
        
        console.log('--- Fin du test manuel ---');
        server.close(() => {
            console.log('Serveur de test arrêté.');
            process.exit(0); // Quitter avec succès
        });
    }
};

// Démarrer le serveur et lancer le test
server.listen(PORT, () => {
    console.log(`Serveur de test démarré sur le port ${PORT}`);
    runTest();
});
