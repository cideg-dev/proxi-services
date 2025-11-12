# Politique de Sécurité de Proxi-Services

## 1. Gestion des authentifications

### JWT
- **Algorithme**: HS256
- **Durée de vie des tokens d'accès**: 15 minutes
- **Durée de vie des refresh tokens**: 7 jours
- **Hachage des mots de passe**: bcrypt (12 rounds)
- **Validation du format des tokens**: Vérification du format Bearer dans l'en-tête Authorization

### Autorisation
- **Contrôle par rôles** (admin, artisan, client)
- **Vérification de propriété des ressources** avec middleware `checkResourceOwnership`
- **Protection des routes sensibles** avec middleware `sensitiveRouteProtection`
- **Gestion des tentatives d'accès multiples** via journalisation

## 2. Validation et Nettoyage des Entrées

### Middleware de sécurité
- **express-mongo-sanitize**: Protection contre les injections NoSQL
- **xss-clean** et validation personnalisée: Nettoyage des entrées contre XSS
- **express-validator**: Validation des données
- **hpp**: Protection contre la pollution de paramètres

### Validation des données
- **Échappement des chaînes**: Toutes les chaînes sont échappées pour éviter XSS
- **Validation des emails**: Utilisation de validator.isEmail()
- **Sanitization des clés de cache**: Empêche les injections dans les clés Redis
- **Limitation de taille**: Limitation des tailles de requêtes et de données

## 3. Configuration de Sécurité

### Helmet
- **CSP (Content Security Policy)**: Restriction des sources de contenu
- **HSTS (HTTP Strict Transport Security)**: Forçage HTTPS pour 1 an
- **Protection contre les attaques de type clickjacking**: frameguard DENY
- **Referrer policy**: strict-origin-when-cross-origin

### Rate Limiting
- **Limite**: 100 requêtes / 15 minutes par IP (500 en développement)
- **Suivi par IP**: Utilisation de l'adresse IP du client pour le suivi
- **Exceptions**: Routes de santé exemptées
- **Réponse**: Code 429 pour trop de requêtes

## 4. Sécurité des Données

### Base de Données
- **Pool de connexions sécurisé**: Configuration avec options de sécurité
- **Validation des variables d'environnement**: Vérification avant démarrage
- **Configuration SSL**: Active en production
- **Connexion timeout**: 2 secondes avant abandon

### Cache
- **Sanitization des clés du cache**: Échappement des caractères dangereux
- **Limitation de la taille des données**: Maximum 1MB par entrée
- **Gestion sécurisée des données expirées**: Nettoyage automatique
- **Sécurité des connexions Redis**: Authentification si disponible

## 5. Journalisation

### Winston
- **Journaux structurés**: Format JSON pour les événements d'authentification
- **Surveillance des accès sensibles**: Journalisation des accès aux routes sensibles
- **Rotation quotidienne**: Des fichiers de log
- **Sécurité des logs**: Aucune information sensible en clair

### Types d'événements surveillés
- **Authentifications réussies/échouées** avec IP et User-Agent
- **Tentatives d'autorisation échouées** avec détails sur le rôle tenté
- **Vérifications de propriété de ressources échouées**
- **Accès aux routes sensibles** avec détails de l'utilisateur et de l'IP

## 6. Surveillances et Alertes

### Surveillance continue
- **Tentatives d'authentification échouées répétées** (à configurer avec un service externe)
- **Accès non autorisés répétés** à des ressources
- **Anomalies de trafic** (à configurer avec un service d'analyse)
- **Accès suspects** aux routes sensibles

### Configuration recommandée
Pour une surveillance efficace, configurez un service d'analyse comme ELK Stack, Datadog ou un système personnalisé qui:
- Agrège les logs Winston
- Détecte les modèles suspects d'accès
- Envoie des alertes en temps réel
- Génère des rapports de sécurité réguliers

## 7. Variables d'Environnement Critiques

### Obligatoires
- `JWT_SECRET`: Clé secrète pour les tokens JWT (minimum 32 caractères)
- `JWT_REFRESH_SECRET`: Clé secrète pour les refresh tokens
- `DATABASE_URL`: URL de la base de données PostgreSQL
- `DB_USER`, `DB_HOST`, `DB_NAME`, `DB_PASSWORD`, `DB_PORT`: Alternatives à DATABASE_URL
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`: Configuration email
- `FRONTEND_URL`: URL de l'interface frontend pour CORS

### Optionnelles mais recommandées
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`: Configuration Redis
- `NODE_ENV`: Environnement (development, production)
- `PORT`: Port d'écoute du serveur (par défaut 3000)

## 8. Gestion des Sessions et des Tokens

### Révocation des Tokens
- **Système de liste noire** pour révoquer les tokens avant leur expiration
- **Endpoint de déconnexion** qui ajoute le token à la liste noire
- **Déconnexion de toutes les sessions** pour un utilisateur spécifique
- **Déconnexion des autres sessions** (garde la session actuelle)

### Sécurité des Sessions
- **Vérification des tokens** contre la liste noire à chaque requête authentifiée
- **Gestion des sessions multiples** avec identification unique
- **Révocation centralisée** des tokens via Redis

## 9. Chiffrement des Données Sensibles

### Chiffrement au Repos
- **AES-256-GCM** pour chiffrer les données sensibles dans la base de données
- **Séparateur clé-IV** pour un chiffrement sécurisé
- **Authentification des données** avec tag pour vérifier l'intégrité

### Données Chiffrées
- **Messages privés** entre utilisateurs
- **Informations personnelles sensibles** dans les profils
- **Données de paiement** et autres informations financières

## 10. Surveillance et Détection des Anomalies

### Surveillance Continue
- **Tentatives d'authentification échouées répétées** 
- **Accès non autorisés répétés** à des ressources
- **Anomalies de trafic** 
- **Accès suspects** aux routes sensibles
- **Détection de comportements suspects** dans les messages et requêtes
- **Journalisation des accès aux routes sensibles**

### Configuration du Système
Le système inclut un service de surveillance des événements de sécurité qui:
- Détecte les tentatives d'authentification répétées depuis la même IP
- Surveille les accès non autorisés répétés à des ressources
- Détecte les comportements suspects dans les messages (XSS, injection SQL, etc.)
- Journalise les accès aux routes sensibles
- Vérifie la taille et le contenu des requêtes pour détecter les attaques potentielles

## 11. Journalisation Sécurisée

### Protection des Logs
- **Masquage des données sensibles** dans les logs d'erreur (mots de passe, tokens, etc.)
- **Nettoyage automatique** des champs sensibles avant enregistrement
- **Format structuré** pour une analyse facilitée
- **Rotation quotidienne** des fichiers de log

### Types d'Événements Surveillés
- **Authentifications réussies/échouées** avec IP et User-Agent
- **Tentatives d'autorisation échouées** avec détails sur le rôle tenté
- **Vérifications de propriété de ressources échouées**
- **Accès aux routes sensibles** avec détails de l'utilisateur et de l'IP

## 12. Tests de Sécurité

### Types de tests
- **Tests d'injection** (SQL, NoSQL, XSS)
- **Tests d'authentification et d'autorisation**
- **Tests de validation des entrées**
- **Tests de sécurité des APIs**
- **Tests de force brute**
- **Tests de déni de service (DoS)**
- **Tests de révocation des tokens**
- **Tests de chiffrement/déchiffrement**

### Outils recommandés
- OWASP ZAP pour les tests d'intrusion
- Postman/Newman pour les tests d'API
- Jest pour les tests unitaires et d'intégration
- SonarQube pour l'analyse statique de code

## 13. Procédures de réponse aux incidents

### En cas de détection d'une vulnérabilité
1. **Isoler immédiatement** l'élément compromis
2. **Analyser la portée** de l'incident
3. **Notifier les parties concernées** (administrateurs, équipe de développement)
4. **Appliquer les correctifs** nécessaires
5. **Vérifier la résolution** avec les outils appropriés
6. **Documenter** l'incident et la résolution

### Contacts en cas d'urgence
- Email de sécurité: security@proxi-services.com
- Responsable technique: tech-lead@proxi-services.com
- Administration: admin@proxi-services.com

---

*Ce document doit être revu et mis à jour régulièrement pour refléter les changements de configuration et les nouvelles menaces de sécurité.*