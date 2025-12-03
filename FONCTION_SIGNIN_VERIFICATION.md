# Vérification de la fonction signin Supabase

## Étapes de vérification

1. **Tester la requête OPTIONS manuellement** :
   Ouvrez votre navigateur et allez dans les outils de développement (F12)
   Allez dans l'onglet "Console" et exécutez :
   
   ```javascript
   fetch('https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1/signin', {
     method: 'OPTIONS',
     headers: {
       'Access-Control-Request-Method': 'POST',
       'Access-Control-Request-Headers': 'Content-Type',
       'Origin': 'https://cideg-dev.github.io'
     }
   })
   .then(response => console.log(response))
   .catch(error => console.error('Erreur:', error));
   ```

2. **Vérifiez les logs de la fonction** dans votre dashboard Supabase :
   - Allez sur https://supabase.com/dashboard/project/ufeqnnbokyalwjfskhmw/functions
   - Cliquez sur la fonction "signin"
   - Allez dans l'onglet "Logs"
   - Essayez de vous connecter et voyez si des erreurs apparaissent

3. **Vérifiez la configuration CORS dans Supabase** :
   Selon votre interface, cela pourrait être :
   - Dans Settings > API
   - Dans Auth > URL Configuration
   - Ou dans une section spécifique CORS

4. **Test de la fonction directement** :
   Essayez d'appeler la fonction directement avec curl ou Postman :
   ```
   curl -X OPTIONS \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -H "Origin: https://cideg-dev.github.io" \
     https://ufeqnnbokyalwjfskhmw.supabase.co/functions/v1/signin
   ```

## Solution potentielle

Si la fonction elle-même est correctement configurée (ce qui semble être le cas), le problème pourrait être dans la configuration globale CORS de votre projet Supabase. Essayez d'ajouter explicitement `https://cideg-dev.github.io` dans la configuration CORS de votre projet Supabase au lieu d'utiliser `*`.

## Dernier recours

Si rien ne fonctionne, vous pouvez temporairement tester avec une fonction qui gère CORS de manière très permissive :
1. Remplacez les en-têtes CORS dans votre fonction par :
   ```
   'Access-Control-Allow-Origin': 'https://cideg-dev.github.io',
   'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
   'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, X-Requested-With',
   'Access-Control-Allow-Credentials': 'true'
   ```
2. Puis redéployez la fonction.