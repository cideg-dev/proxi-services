#!/bin/bash
# Script de déploiement des fonctions Supabase

set -e  # Quitter en cas d'erreur

echo "Début du déploiement des fonctions Supabase..."

# Vérifier si supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "Erreur: Supabase CLI n'est pas installé."
    echo "Installez-le avec: npm install -g @supabase/cli"
    exit 1
fi

# Se connecter à Supabase (nécessite d'avoir fait supabase login auparavant)
echo "Connexion à Supabase..."

# Déployer chaque fonction
echo "Déploiement de la fonction artisans..."
supabase functions deploy artisans

echo "Déploiement de la fonction professionals..."
supabase functions deploy professionals

echo "Déploiement de la fonction signup..."
supabase functions deploy signup

echo "Déploiement de la fonction signin..."
supabase functions deploy signin

echo "Déploiement de la fonction reviews..."
supabase functions deploy reviews

echo "Toutes les fonctions ont été déployées avec succès!"
echo "Vérifiez le tableau de bord Supabase pour confirmer le déploiement."