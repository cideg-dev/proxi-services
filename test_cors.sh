#!/bin/bash
# Script de test pour vérifier la réponse OPTIONS de la fonction

echo "Test de la réponse OPTIONS pour la fonction signin..."
curl -v -X OPTIONS \
  -H "Origin: https://cideg-dev.github.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1/signin