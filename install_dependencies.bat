#!/bin/bash
# Script d'installation des dépendances pour Proxi-Services

echo "Installation des dépendances pour Proxi-Services..."

# Se déplacer dans le répertoire frontend
cd frontend

# Installation des dépendances Flutter
flutter clean
flutter pub get

echo "Dépendances installées avec succès !"

# Affichage des instructions de compilation
echo ""
echo "Pour compiler l'application :"
echo "flutter build apk"
echo "ou"
echo "flutter run"