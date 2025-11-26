const dotenv = require('dotenv');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const db = require('../../../db.config'); // Assurez-vous que le chemin est correct
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

dotenv.config();

// Initialiser le client Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Fonction pour générer le contenu du portfolio
exports.generatePortfolio = async (req, res) => {
    const { description } = req.body;
    const userId = req.user.id;

    if (!description) {
        return res.status(400).json({ error: 'La description est requise.' });
    }

    if (!process.env.GEMINI_API_KEY) {
        return res.status(500).json({ error: 'La clé API Gemini n\'est pas configurée.' });
    }

    const client = await db.connect();

    try {
        const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

        const prompt = `
            En tant qu'expert en marketing et image de marque pour artisans, analyse la description suivante d'un professionnel et génère un contenu de portfolio complet et attractif.
            Description de l'artisan : "${description}"

            Génère une réponse au format JSON contenant les clés suivantes :
            1. "bio": Une biographie professionnelle et engageante de 2 à 3 phrases.
            2. "services": Une liste de 3 à 5 services clés offerts, sous forme d'un tableau d'objets avec les clés "name" et "description".
            3. "image_prompts": Une liste de 4 prompts détaillés et variés pour un modèle de génération d'images qui mettront en valeur le savoir-faire de l'artisan.

            Assure-toi que le JSON est valide et bien formaté.
        `;

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        const cleanedText = text.replace(/```json/g, '').replace(/```/g, '').trim();
        const generatedContent = JSON.parse(cleanedText);

        const { bio, services, image_prompts } = generatedContent;

        await client.query('BEGIN');

        await client.query('UPDATE artisan_profiles SET description = $1 WHERE user_id = $2', [bio, userId]);
        
        await client.query('DELETE FROM services WHERE artisan_id = $1', [userId]);
        for (const service of services) {
            await client.query('INSERT INTO services (artisan_id, name, description) VALUES ($1, $2, $3)', [userId, service.name, service.description || '']);
        }

        // --- Logique d'image ---
        // 1. Supprimer les anciens items du portfolio de la DB
        // Note : Ceci ne supprime pas les fichiers physiques, une tâche de nettoyage pourrait être nécessaire.
        await client.query('DELETE FROM portfolio_items WHERE artisan_id = $1', [userId]);

        // 2. Générer et sauvegarder les nouvelles images
        const imageGenerationModel = genAI.getGenerativeModel({ model: "gemini-pro-vision" }); // NOTE: Le nom du modèle pour la génération d'image peut varier.
        
        for (const imgPrompt of image_prompts) {
            // SIMULATION de la génération d'image. Remplacer par un appel réel à l'API.
            // Pour la démo, nous créons un simple buffer d'image PNG gris.
            const placeholderImageBuffer = Buffer.from(
                `<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg"><rect width="500" height="500" fill="#cccccc"/><text x="50%" y="50%" font-family="Arial" font-size="20" fill="white" text-anchor="middle" dy=".3em">Image pour : ${imgPrompt.substring(0, 30)}...</text></svg>`
            );

            const filename = `${crypto.randomUUID()}.svg`;
            const filePath = path.join(__dirname, '../../../uploads/portfolio', filename);
            const fileUrl = `/uploads/portfolio/${filename}`;

            // Sauvegarder le fichier sur le disque
            fs.writeFileSync(filePath, placeholderImageBuffer);

            // 3. Insérer l'URL de l'image dans la base de données
            await client.query(
                'INSERT INTO portfolio_items (artisan_id, image_url, caption) VALUES ($1, $2, $3)',
                [userId, fileUrl, imgPrompt]
            );
        }
        // --- Fin de la logique d'image ---

        await client.query('COMMIT');
        
        res.status(200).json({
            message: "Portfolio généré et sauvegardé avec succès !",
            data: { bio, services, image_prompts }
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Erreur lors de la génération ou de la sauvegarde du portfolio :', error);
        res.status(500).json({ error: 'Une erreur est survenue lors de la mise à jour du portfolio.' });
    } finally {
        client.release();
    }
};
