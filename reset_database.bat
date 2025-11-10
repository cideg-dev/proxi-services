#!/bin/bash
# Script pour réinitialiser la base de données

# Vérifier si le script est exécuté depuis le bon répertoire
if [ ! -f "backend/package.json" ]; then
  echo "ERREUR: Ce script doit être exécuté depuis le répertoire racine du projet"
  exit 1
fi

echo "Arrêt de l'application (si en cours d'exécution)..."
# Aucun processus spécifique à arrêter car l'application n'est probablement pas lancée

echo "Connexion à la base de données et suppression des données..."
cd backend

# Exécuter le script de réinitialisation de la base de données
npm run reset-db

if [ $? -eq 0 ]; then
  echo "✅ Réinitialisation de la base de données terminée avec succès"
else
  echo "❌ Erreur lors de la réinitialisation de la base de données"
  exit 1
fi

echo "La base de données a été vidée. Les prochaines inscriptions d'utilisateurs recommenceront à partir du début."