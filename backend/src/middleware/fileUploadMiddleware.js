const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

// Configuration de stockage pour Multer
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Créer le répertoire uploads s'il n'existe pas
    const uploadDir = 'uploads/profile-pictures';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    // Générer un nom de fichier unique basé sur l'ID utilisateur et l'horodatage
    const userId = req.user.user.id;
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueFilename = `${userId}_${Date.now()}${ext}`;
    cb(null, uniqueFilename);
  }
});

// Filtre pour les types de fichiers autorisés
const fileFilter = (req, file, cb) => {
  // Autoriser uniquement les images
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Type de fichier non autorisé. Seules les images sont autorisées.'), false);
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // Limite à 5 Mo
  }
});

// Middleware de gestion des erreurs Multer
const handleUploadError = (error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ 
        message: 'La taille du fichier est trop grande. Maximum 5 Mo autorisé.' 
      });
    }
    if (error.code === 'LIMIT_UNEXPECTED_FILE') {
      return res.status(400).json({ 
        message: 'Nom de champ de fichier incorrect. Utilisez \'photo\'.' 
      });
    }
    return res.status(400).json({ 
      message: 'Erreur lors de l\'upload du fichier.' 
    });
  } else if (error.message === 'Type de fichier non autorisé. Seules les images sont autorisées.') {
    return res.status(400).json({ 
      message: error.message 
    });
  }
  
  next(error);
};

module.exports = {
  upload,
  handleUploadError
};