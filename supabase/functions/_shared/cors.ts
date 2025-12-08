// supabase/functions/_shared/cors.ts
// Configuration CORS sécurisée pour les fonctions Supabase

/**
 * En-têtes CORS sécurisés
 */
export const secureCorsHeaders = {
  "Access-Control-Allow-Origin": "https://cideg-dev.github.io", // Remplacez par votre domaine de production
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Max-Age": "86400", // 24 heures
};

/**
 * Génère les en-têtes CORS en fonction de l'origine
 * @param origin L'origine de la requête
 * @returns Les en-têtes CORS appropriés
 */
export function getCorsHeaders(origin?: string): { [key: string]: string } {
  // Pour les environnements de développement ou les tests, vous pouvez avoir des origines supplémentaires
  const allowedOrigins = [
    "https://cideg-dev.github.io",
    "http://localhost:3000",
    "http://localhost:5173",
    // Ajoutez d'autres origines de confiance si nécessaire
  ];

  // Si l'origine est dans la liste, l'autoriser explicitement, sinon utiliser l'origine par défaut
  const originToUse = origin && allowedOrigins.includes(origin) ? origin : secureCorsHeaders["Access-Control-Allow-Origin"];

  return {
    ...secureCorsHeaders,
    "Access-Control-Allow-Origin": originToUse,
  };
}

/**
 * Génère une réponse CORS pour les requêtes OPTIONS
 * @param req La requête entrante
 * @returns Une réponse appropriée pour les requêtes préliminaires
 */
export function createOptionsResponse(req: Request): Response {
  const origin = req.headers.get("Origin");
  const corsHeaders = getCorsHeaders(origin);
  
  return new Response(null, {
    status: 204, // No Content
    headers: corsHeaders
  });
}