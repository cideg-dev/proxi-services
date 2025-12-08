// supabase/functions/_shared/tokenUtils.ts
// Utilitaires de gestion sécurisée des tokens pour les fonctions Supabase

/**
 * Extrait de manière sécurisée le token JWT de l'en-tête Authorization
 * @param headers Les en-têtes de la requête
 * @returns Le token JWT ou null s'il n'est pas valide
 */
export function extractTokenFromHeaders(headers: Headers): string | null {
  const authHeader = headers.get('Authorization');
  
  if (!authHeader) {
    return null;
  }

  // Vérifier que le format est correct (Bearer token)
  const parts = authHeader.trim().split(' ');
  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') {
    return null;
  }

  const token = parts[1].trim();
  if (!token) {
    return null;
  }

  return token;
}

/**
 * Valide le format d'un token JWT
 * @param token Le token à valider
 * @returns true si le token est dans un format valide, false sinon
 */
export function isValidJWTFormat(token: string): boolean {
  // Un JWT valide a 3 parties séparées par des points
  const parts = token.split('.');
  if (parts.length !== 3) {
    return false;
  }

  // Vérifier que chaque partie est correctement encodée en base64
  const base64Regex = /^[A-Za-z0-9-_]+$/;
  return parts.every(part => base64Regex.test(part));
}