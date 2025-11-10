const { pool } = require('../db.config');
const { logger, logError } = require('../utils/logger');
const { getFromCache, saveToCache } = require('../services/cacheService');

// Contrôleur de santé
const healthCheck = (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV
  });
};

// Contrôleur pour obtenir la version
const getVersion = (req, res) => {
  res.status(200).json({
    success: true,
    version: process.env.npm_package_version || '1.0.0',
    build: new Date().toISOString()
  });
};

// Contrôleur pour obtenir les artisans avec cache et pagination
const getArtisans = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const category = req.query.category || '';

    // Clé de cache unique pour cette requête
    const cacheKey = `artisans:${page}:${limit}:${search}:${category}`;

    // Essayer d'abord le cache
    const cachedResult = await getFromCache(cacheKey);
    if (cachedResult) {
      logger.info('CACHE_HIT', { cacheKey, ip: req.ip });
      return res.status(200).json({
        success: true,
        ...cachedResult,
        fromCache: true
      });
    }

    // Construction de la requête SQL avec recherche et filtres
    let query = `
      SELECT 
        u.id,
        u.role,
        u.email,
        u.is_active,
        u.is_verified,
        a.nom_complet,
        a.specialty,
        a.description,
        a.années_experience,
        a.horaires_ouverture,
        a.assurance_professionnelle,
        a.langues_parlees,
        a.rating,
        a.nombre_avis,
        a.localisation,
        a.latitude,
        a.longitude
      FROM users u
      JOIN artisan_profiles a ON u.id = a.user_id
      WHERE u.is_active = true AND u.is_verified = true
    `;
    
    const params = [];
    let paramIndex = 1;

    if (search) {
      query += ` AND (a.nom_complet ILIKE $${paramIndex} OR a.specialty ILIKE $${paramIndex} OR a.description ILIKE $${paramIndex})`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    if (category && category !== 'all') {
      query += ` AND a.specialty ILIKE $${paramIndex}`;
      params.push(`%${category}%`);
      paramIndex++;
    }

    // Compter le nombre total d'artisans
    const countQuery = query.replace(/SELECT \* FROM/, 'SELECT COUNT(*) FROM')
                            .replace(/SELECT \w+.*?, \w+.*?,/, 'SELECT')
                            .replace(/LIMIT.*/g, '')
                            .replace(/OFFSET.*/g, '');
    const countResult = await pool.query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);

    // Ajouter la pagination
    query += ` ORDER BY a.rating DESC, a.nombre_avis DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    const response = {
      success: true,
      data: result.rows,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalItems: total,
        itemsPerPage: limit,
        hasNextPage: page < Math.ceil(total / limit),
        hasPrevPage: page > 1
      }
    };

    // Sauvegarder dans le cache pour 5 minutes
    await saveToCache(cacheKey, response, 300);

    logger.info('ARTISANS_FETCHED', { 
      count: result.rows.length, 
      page, 
      limit, 
      search, 
      category,
      ip: req.ip 
    });

    res.status(200).json(response);
  } catch (error) {
    logError(error, req, { operation: 'getArtisans' });
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération des artisans'
    });
  }
};

// Contrôleur pour obtenir un artisan spécifique avec cache
const getArtisan = async (req, res) => {
  try {
    const { id } = req.params;

    // Validation de l'ID
    if (!id || isNaN(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID d\'artisan invalide'
      });
    }

    // Clé de cache pour cet artisan spécifique
    const cacheKey = `artisan:${id}`;

    // Essayer d'abord le cache
    const cachedResult = await getFromCache(cacheKey);
    if (cachedResult) {
      logger.info('CACHE_HIT', { cacheKey, ip: req.ip });
      return res.status(200).json({
        success: true,
        ...cachedResult,
        fromCache: true
      });
    }

    // Récupérer les détails de l'artisan avec ses services et portfolio
    const query = `
      SELECT 
        u.id,
        u.email,
        u.is_active,
        u.is_verified,
        a.nom_complet,
        a.specialty,
        a.description,
        a.années_experience,
        a.horaires_ouverture,
        a.assurance_professionnelle,
        a.langues_parlees,
        a.rating,
        a.nombre_avis,
        a.localisation,
        a.latitude,
        a.longitude,
        a.photo_url,
        -- Récupérer les services de l'artisan
        (SELECT json_agg(json_build_object(
          'id', s.id,
          'title', s.title,
          'description', s.description,
          'price', s.price,
          'category', s.category
        )) FROM services s WHERE s.artisan_id = u.id) AS services,
        -- Récupérer le portfolio de l'artisan
        (SELECT json_agg(json_build_object(
          'id', p.id,
          'name', p.name,
          'description', p.description,
          'image_url', p.image_url,
          'price', p.price
        )) FROM portfolio_items p WHERE p.artisan_id = u.id) AS portfolio
      FROM users u
      JOIN artisan_profiles a ON u.id = a.user_id
      WHERE u.id = $1 AND u.is_active = true
    `;

    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Artisan non trouvé'
      });
    }

    const response = {
      success: true,
      data: result.rows[0]
    };

    // Sauvegarder dans le cache pour 1 heure
    await saveToCache(cacheKey, response, 3600);

    logger.info('ARTISAN_FETCHED', { artisanId: id, ip: req.ip });

    res.status(200).json(response);
  } catch (error) {
    logError(error, req, { operation: 'getArtisan', artisanId: req.params.id });
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération de l\'artisan'
    });
  }
};

// Contrôleur de performance pour tester les temps de réponse
const performanceTest = async (req, res) => {
  const start = Date.now();
  
  try {
    // Effectuer une requête simple pour mesurer la performance
    const result = await pool.query('SELECT 1 as test');
    
    const responseTime = Date.now() - start;
    
    res.status(200).json({
      success: true,
      message: 'Test de performance réussi',
      responseTime: `${responseTime}ms`,
      database: result.rows[0].test
    });
  } catch (error) {
    logError(error, req, { operation: 'performanceTest' });
    res.status(500).json({
      success: false,
      message: 'Erreur lors du test de performance'
    });
  }
};

module.exports = {
  healthCheck,
  getVersion,
  getArtisans,
  getArtisan,
  performanceTest
};