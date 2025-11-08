-- Script pour ajouter les colonnes manquantes dans la base de données

-- Ajouter la colonne created_at dans la table users si elle n'existe pas
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Ajouter la colonne avis_moyen dans la table artisan_profiles si elle n'existe pas
ALTER TABLE artisan_profiles ADD COLUMN IF NOT EXISTS avis_moyen DECIMAL(3,2) DEFAULT 0.00;

-- Mise à jour de la colonne avis_moyen avec la moyenne des avis pour chaque artisan
UPDATE artisan_profiles 
SET avis_moyen = (
    SELECT AVG(rating) 
    FROM reviews 
    WHERE reviews.artisan_id = artisan_profiles.user_id
) 
WHERE user_id IN (SELECT DISTINCT artisan_id FROM reviews);