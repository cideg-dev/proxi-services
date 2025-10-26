"""const express = require('express');
const router = express.Router();
const pool = require('../db.config');
const { check, validationResult, body } = require('express-validator');
const { authenticateToken } = require('../middleware/authMiddleware');
const { calculateProfileCompleteness } = require('../services/profileService');

module.exports = function() {
  // GET /api/profile - Get logged-in user's profile and completeness
  router.get('/', authenticateToken, async (req, res) => {
    const userId = req.user.user.id;
    const userRole = req.user.user.role;

    try {
      // The user's email and role are fundamental, let's get them directly.
      const userResult = await pool.query('SELECT email, role FROM users WHERE id = $1', [userId]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }
      const userData = userResult.rows[0];

      let profileData = null;
      let profileCompleteness = 0;
      let profileQuery = '';

      if (userRole === 'client') {
        profileQuery = 'SELECT * FROM client_profiles WHERE user_id = $1';
      } else if (userRole === 'artisan') {
        profileQuery = 'SELECT * FROM artisan_profiles WHERE user_id = $1';
      } else if (userRole === 'commercant') {
        profileQuery = 'SELECT * FROM commercant_profiles WHERE user_id = $1';
      }

      if (profileQuery) {
        const profileResult = await pool.query(profileQuery, [userId]);
        if (profileResult.rows.length > 0) {
          profileData = profileResult.rows[0];
          profileCompleteness = calculateProfileCompleteness(profileData, userRole);
        }
      }

      // Combine user data and profile data
      const fullProfile = {
        ...userData, // email, role
        ...(profileData || {}) // all fields from the specific profile table
      };

      res.json({ profile: fullProfile, completeness: profileCompleteness });

    } catch (error) {
      console.error('Error fetching user profile:', error);
      res.status(500).json({ message: 'Erreur interne du serveur lors de la récupération du profil.' });
    }
  });

  // GET /api/profile/:userId - Get a specific user's profile and completeness
  router.get('/:userId', authenticateToken, async (req, res) => {
    const requestedUserId = parseInt(req.params.userId);
    const loggedInUserId = req.user.user.id;
    const loggedInUserRole = req.user.user.role;

    // Authorization: Only the user themselves or an admin can view a specific profile
    if (loggedInUserId !== requestedUserId && loggedInUserRole !== 'admin') {
      return res.status(403).json({ message: 'Action non autorisée. Vous ne pouvez voir que votre propre profil ou être administrateur.' });
    }

    try {
      // The user's email and role are fundamental, let's get them directly.
      const userResult = await pool.query('SELECT id, email, role FROM users WHERE id = $1', [requestedUserId]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ message: 'Utilisateur non trouvé.' });
      }
      const userData = userResult.rows[0];
      const userRole = userData.role;

      let profileData = null;
      let profileCompleteness = 0;
      let profileQuery = '';

      if (userRole === 'client') {
        profileQuery = 'SELECT * FROM client_profiles WHERE user_id = $1';
      } else if (userRole === 'artisan') {
        profileQuery = 'SELECT * FROM artisan_profiles WHERE user_id = $1';
      } else if (userRole === 'commercant') {
        profileQuery = 'SELECT * FROM commercant_profiles WHERE user_id = $1';
      }

      if (profileQuery) {
        const profileResult = await pool.query(profileQuery, [requestedUserId]);
        if (profileResult.rows.length > 0) {
          profileData = profileResult.rows[0];
          profileCompleteness = calculateProfileCompleteness(profileData, userRole);
        }
      }

      // Combine user data and profile data
      const fullProfile = {
        ...userData, // id, email, role
        ...(profileData || {})
      };

      res.json({ profile: fullProfile, completeness: profileCompleteness });

    } catch (error) {
      console.error('Error fetching specific user profile:', error);
      res.status(500).json({ message: 'Erreur interne du serveur lors de la récupération du profil.' });
    }
  });

  // POST /api/profile - Create a new profile for the logged-in user
  router.post('/', authenticateToken,
    [
      // General email validation (optional as email is from user token)
      check('email', 'Veuillez inclure un email valide').optional().isEmail(),

      // Client profile validation
      body('nom_complet', 'Le nom complet est requis').if(body('role').equals('client')).notEmpty(),
      body('location', 'La localisation est requise').if(body('role').equals('client')).notEmpty(),

      // Artisan profile validation
      body('nom_complet', 'Le nom complet est requis').if(body('role').equals('artisan')).notEmpty(),
      body('specialite', 'La spécialité est requise').if(body('role').equals('artisan')).notEmpty(),
      body('location', 'La localisation est requise').if(body('role').equals('artisan')).notEmpty(),

      // Commercant profile validation
      body('nom_entreprise', 'Le nom de l'entreprise est requis').if(body('role').equals('commercant')).notEmpty(),
      body('adresse', 'L'adresse est requise').if(body('role').equals('commercant')).notEmpty(),
      body('location', 'La localisation est requise').if(body('role').equals('commercant')).notEmpty(),
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.user.id;
      const userRole = req.user.user.role;
      const profileData = req.body;

      const client = await pool.connect();

      try {
        await client.query('BEGIN');

        // Check if a profile already exists
        let profileCheck;
        if (userRole === 'client') {
          profileCheck = await client.query('SELECT user_id FROM client_profiles WHERE user_id = $1', [userId]);
        } else if (userRole === 'artisan') {
          profileCheck = await client.query('SELECT user_id FROM artisan_profiles WHERE user_id = $1', [userId]);
        } else if (userRole === 'commercant') {
          profileCheck = await client.query('SELECT user_id FROM commercant_profiles WHERE user_id = $1', [userId]);
        }

        if (profileCheck.rows.length > 0) {
          await client.query('ROLLBACK');
          return res.status(409).json({ message: 'Un profil existe déjà pour cet utilisateur.' });
        }

        let newProfile;

        if (userRole === 'client') {
          const { nom_complet, sexe, location, telephone, photo_url, adresse } = profileData;
          const result = await client.query(
            'INSERT INTO client_profiles (user_id, nom_complet, sexe, location, telephone, photo_url, adresse) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
            [userId, nom_complet, sexe, location, telephone, photo_url, adresse]
          );
          newProfile = result.rows[0];
        } else if (userRole === 'artisan') {
          const { nom_complet, sexe, specialite, description, location, telephone, annees_experience, siret, site_web, photo_url, horaires_ouverture, langues_parlees, assurance_professionnelle } = profileData;
          const result = await client.query(
            'INSERT INTO artisan_profiles (user_id, nom_complet, sexe, specialite, description, location, telephone, annees_experience, siret, site_web, photo_url, horaires_ouverture, langues_parlees, assurance_professionnelle) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING *',
            [userId, nom_complet, sexe, specialite, description, location, telephone, annees_experience, siret, site_web, photo_url, horaires_ouverture, langues_parlees, assurance_professionnelle]
          );
          newProfile = result.rows[0];
        } else if (userRole === 'commercant') {
          const { nom_entreprise, sexe_contact, type_commerce, description, adresse, location, telephone, siret, site_web, horaires_ouverture, photo_url, langues_parlees, assurance_professionnelle } = profileData;
          const result = await client.query(
            'INSERT INTO commercant_profiles (user_id, nom_entreprise, sexe_contact, type_commerce, description, adresse, location, telephone, siret, site_web, horaires_ouverture, photo_url, langues_parlees, assurance_professionnelle) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING *',
            [userId, nom_entreprise, sexe_contact, type_commerce, description, adresse, location, telephone, siret, site_web, horaires_ouverture, photo_url, langues_parlees, assurance_professionnelle]
          );
          newProfile = result.rows[0];
        } else {
          await client.query('ROLLBACK');
          return res.status(400).json({ message: 'Rôle utilisateur inconnu.' });
        }

        await client.query('COMMIT');

        res.status(201).json({ message: 'Profil créé avec succès.', profile: newProfile });

      } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error creating user profile:', error);
        res.status(500).json({ message: 'Erreur lors de la création du profil.' });
      } finally {
        client.release();
      }
    });

  // PUT /api/profile - Update logged-in user's profile
  router.put('/', authenticateToken,
    [
      // General email validation
      check('email', 'Veuillez inclure un email valide').optional().isEmail(),

      // Client profile validation
      body('nom_complet', 'Le nom complet est requis').if(body('role').equals('client')).optional().notEmpty(),
      body('location', 'La localisation est requise').if(body('role').equals('client')).optional().notEmpty(),

      // Artisan profile validation
      body('nom_complet', 'Le nom complet est requis').if(body('role').equals('artisan')).optional().notEmpty(),
      body('specialite', 'La spécialité est requise').if(body('role').equals('artisan')).optional().notEmpty(),
      body('location', 'La localisation est requise').if(body('role').equals('artisan')).optional().notEmpty(),

      // Commercant profile validation
      body('nom_entreprise', 'Le nom de l'entreprise est requis').if(body('role').equals('commercant')).optional().notEmpty(),
      body('adresse', 'L'adresse est requise').if(body('role').equals('commercant')).optional().notEmpty(),
      body('location', 'La localisation est requise').if(body('role').equals('commercant')).optional().notEmpty(),
    ],
    async (req, res) => {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.user.id;
      const userRole = req.user.user.role;
      const { email, ...profileData } = req.body;

      const client = await pool.connect();

      try {
        await client.query('BEGIN');

        // Update email in users table if provided
        if (email !== undefined) {
          const emailCheck = await client.query('SELECT id FROM users WHERE email = $1 AND id != $2', [email, userId]);
          if (emailCheck.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ message: 'Cet email est déjà utilisé par un autre utilisateur.' });
          }
          await client.query('UPDATE users SET email = $1 WHERE id = $2', [email, userId]);
        }

        let updatedProfile;
        let profileCompletenessPercentage = 0;

        // Update profile table based on role
        const updates = [];
        const values = [];
        let paramIndex = 1;

        if (userRole === 'client') {
          if (profileData.nom_complet !== undefined) { updates.push(`nom_complet = $${paramIndex++}`); values.push(profileData.nom_complet); }
          if (profileData.sexe !== undefined) { updates.push(`sexe = $${paramIndex++}`); values.push(profileData.sexe); }
          if (profileData.location !== undefined) { updates.push(`location = $${paramIndex++}`); values.push(profileData.location); }
          if (profileData.telephone !== undefined) { updates.push(`telephone = $${paramIndex++}`); values.push(profileData.telephone); }
          if (profileData.photo_url !== undefined) { updates.push(`photo_url = $${paramIndex++}`); values.push(profileData.photo_url); }
          if (profileData.adresse !== undefined) { updates.push(`adresse = $${paramIndex++}`); values.push(profileData.adresse); }

          if (updates.length > 0) {
            values.push(userId);
            const profileUpdateQuery = `UPDATE client_profiles SET ${updates.join(', ')} WHERE user_id = $${paramIndex} RETURNING *`;
            const result = await client.query(profileUpdateQuery, values);
            updatedProfile = result.rows[0];
          }
        } else if (userRole === 'artisan') {
          if (profileData.nom_complet !== undefined) { updates.push(`nom_complet = $${paramIndex++}`); values.push(profileData.nom_complet); }
          if (profileData.sexe !== undefined) { updates.push(`sexe = $${paramIndex++}`); values.push(profileData.sexe); }
          if (profileData.specialite !== undefined) { updates.push(`specialite = $${paramIndex++}`); values.push(profileData.specialite); }
          if (profileData.description !== undefined) { updates.push(`description = $${paramIndex++}`); values.push(profileData.description); }
          if (profileData.location !== undefined) { updates.push(`location = $${paramIndex++}`); values.push(profileData.location); }
          if (profileData.telephone !== undefined) { updates.push(`telephone = $${paramIndex++}`); values.push(profileData.telephone); }
          if (profileData.annees_experience !== undefined) { updates.push(`annees_experience = $${paramIndex++}`); values.push(profileData.annees_experience); }
          if (profileData.siret !== undefined) { updates.push(`siret = $${paramIndex++}`); values.push(profileData.siret); }
          if (profileData.site_web !== undefined) { updates.push(`site_web = $${paramIndex++}`); values.push(profileData.site_web); }
          if (profileData.photo_url !== undefined) { updates.push(`photo_url = $${paramIndex++}`); values.push(profileData.photo_url); }
          if (profileData.document_verification_url !== undefined) { updates.push(`document_verification_url = $${paramIndex++}`); values.push(profileData.document_verification_url); }
          if (profileData.horaires_ouverture !== undefined) { updates.push(`horaires_ouverture = $${paramIndex++}`); values.push(profileData.horaires_ouverture); }
          if (profileData.langues_parlees !== undefined) { updates.push(`langues_parlees = $${paramIndex++}`); values.push(profileData.langues_parlees); }
          if (profileData.assurance_professionnelle !== undefined) { updates.push(`assurance_professionnelle = $${paramIndex++}`); values.push(profileData.assurance_professionnelle); }

          if (updates.length > 0) {
            values.push(userId);
            const profileUpdateQuery = `UPDATE artisan_profiles SET ${updates.join(', ')} WHERE user_id = $${paramIndex} RETURNING *`;
            const result = await client.query(profileUpdateQuery, values);
            updatedProfile = result.rows[0];
          }
        } else if (userRole === 'commercant') {
          if (profileData.nom_entreprise !== undefined) { updates.push(`nom_entreprise = $${paramIndex++}`); values.push(profileData.nom_entreprise); }
          if (profileData.sexe_contact !== undefined) { updates.push(`sexe_contact = $${paramIndex++}`); values.push(profileData.sexe_contact); }
          if (profileData.type_commerce !== undefined) { updates.push(`type_commerce = $${paramIndex++}`); values.push(profileData.type_commerce); }
          if (profileData.description !== undefined) { updates.push(`description = $${paramIndex++}`); values.push(profileData.description); }
          if (profileData.adresse !== undefined) { updates.push(`adresse = $${paramIndex++}`); values.push(profileData.adresse); }
          if (profileData.location !== undefined) { updates.push(`location = $${paramIndex++}`); values.push(profileData.location); }
          if (profileData.telephone !== undefined) { updates.push(`telephone = $${paramIndex++}`); values.push(profileData.telephone); }
          if (profileData.siret !== undefined) { updates.push(`siret = $${paramIndex++}`); values.push(profileData.siret); }
          if (profileData.site_web !== undefined) { updates.push(`site_web = $${paramIndex++}`); values.push(profileData.site_web); }
          if (profileData.horaires_ouverture !== undefined) { updates.push(`horaires_ouverture = $${paramIndex++}`); values.push(profileData.horaires_ouverture); }
          if (profileData.photo_url !== undefined) { updates.push(`photo_url = $${paramIndex++}`); values.push(profileData.photo_url); }
          if (profileData.document_verification_url !== undefined) { updates.push(`document_verification_url = $${paramIndex++}`); values.push(profileData.document_verification_url); }
          if (profileData.langues_parlees !== undefined) { updates.push(`langues_parlees = $${paramIndex++}`); values.push(profileData.langues_parlees); }
          if (profileData.assurance_professionnelle !== undefined) { updates.push(`assurance_professionnelle = $${paramIndex++}`); values.push(profileData.assurance_professionnelle); }

          if (updates.length > 0) {
            values.push(userId);
            const profileUpdateQuery = `UPDATE commercant_profiles SET ${updates.join(', ')} WHERE user_id = $${paramIndex} RETURNING *`;
            const result = await client.query(profileUpdateQuery, values);
            updatedProfile = result.rows[0];
          }
        } else {
          await client.query('ROLLBACK');
          return res.status(400).json({ message: 'Rôle utilisateur inconnu.' });
        }

        // Refetch the full profile to include all changes
        const userResult = await client.query('SELECT email, role FROM users WHERE id = $1', [userId]);
        const userData = userResult.rows[0];

        let newProfileData = null;
        if (userRole === 'client') {
          const profileResult = await client.query('SELECT * FROM client_profiles WHERE user_id = $1', [userId]);
          if (profileResult.rows.length > 0) newProfileData = profileResult.rows[0];
        } else if (userRole === 'artisan') {
          const profileResult = await client.query('SELECT * FROM artisan_profiles WHERE user_id = $1', [userId]);
          if (profileResult.rows.length > 0) newProfileData = profileResult.rows[0];
        } else if (userRole === 'commercant') {
          const profileResult = await client.query('SELECT * FROM commercant_profiles WHERE user_id = $1', [userId]);
          if (profileResult.rows.length > 0) newProfileData = profileResult.rows[0];
        }

        const fullProfile = {
          ...userData,
          ...(newProfileData || {})
        };
        
        profileCompletenessPercentage = calculateProfileCompleteness(fullProfile, userRole);

        await client.query('COMMIT');

        res.json({ message: 'Profil mis à jour avec succès.', profile: fullProfile, completeness: profileCompletenessPercentage });

      } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Erreur lors de la mise à jour du profil.' });
      } finally {
        client.release();
      }
    });

  return router;
};
""