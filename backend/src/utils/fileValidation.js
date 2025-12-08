// backend/src/utils/fileValidation.js
const path = require('path');
const FileType = require('file-type');
const { promisify } = require('util');
const fs = require('fs');

// Fonction pour valider le type de fichier
async function validateFileType(filePath, allowedMimeTypes = []) {
  try {
    // Obtenir le type de fichier à partir des octets
    const fileType = await FileType.fromFile(filePath);
    
    if (!fileType) {
      throw new Error('Impossible de déterminer le type de fichier');
    }

    // Vérifier si le type MIME est autorisé
    if (allowedMimeTypes.length > 0 && !allowedMimeTypes.includes(fileType.mime)) {
      throw new Error(`Type de fichier non autorisé: ${fileType.mime}. Types autorisés: ${allowedMimeTypes.join(', ')}`);
    }

    return {
      valid: true,
      mimeType: fileType.mime,
      extension: fileType.ext
    };
  } catch (error) {
    return {
      valid: false,
      error: error.message
    };
  }
}

// Fonction pour valider la signature du fichier
function validateFileSignature(buffer, expectedExtensions = []) {
  // Tableau des signatures de fichier connues
  const fileSignatures = {
    'jpg': [0xFF, 0xD8, 0xFF],
    'jpeg': [0xFF, 0xD8, 0xFF],
    'png': [0x89, 0x50, 0x4E, 0x47],
    'gif': [0x47, 0x49, 0x46, 0x38],
    'pdf': [0x25, 0x50, 0x44, 0x46],
    'zip': [0x50, 0x4B],
    'docx': [0x50, 0x4B], // Les fichiers DOCX sont en fait des archives ZIP
    'xlsx': [0x50, 0x4B], // Les fichiers XLSX sont en fait des archives ZIP
    'pptx': [0x50, 0x4B], // Les fichiers PPTX sont en fait des archives ZIP
  };

  // Vérifier la signature pour chaque extension autorisée
  for (const ext of expectedExtensions) {
    if (fileSignatures[ext]) {
      const signature = fileSignatures[ext];
      let match = true;
      for (let i = 0; i < signature.length; i++) {
        if (buffer[i] !== signature[i]) {
          match = false;
          break;
        }
      }
      if (match) {
        return { valid: true, extension: ext };
      }
    }
  }

  return { valid: false, error: 'Signature de fichier non reconnue ou non autorisée' };
}

// Fonction de validation complète d'un fichier
async function validateFile(file, options = {}) {
  const {
    allowedMimeTypes = [],
    allowedExtensions = [],
    maxSize = 5 * 1024 * 1024, // 5 Mo par défaut
    checkSignature = true
  } = options;

  // Vérifier la taille du fichier
  if (file.size > maxSize) {
    throw new Error(`La taille du fichier dépasse la limite autorisée de ${maxSize} octets`);
  }

  // Vérifier l'extension du fichier si des extensions sont spécifiées
  if (allowedExtensions.length > 0) {
    const fileExt = path.extname(file.originalname).toLowerCase().substring(1);
    if (!allowedExtensions.includes(fileExt)) {
      throw new Error(`Extension de fichier non autorisée: ${fileExt}. Extensions autorisées: ${allowedExtensions.join(', ')}`);
    }
  }

  // Si la validation de la signature est activée
  if (checkSignature && allowedExtensions.length > 0) {
    // Lire une partie du fichier pour la validation de signature
    const buffer = await promisify(fs.readFile)(file.path);
    const signatureValidation = validateFileSignature(buffer, allowedExtensions);
    
    if (!signatureValidation.valid) {
      throw new Error(signatureValidation.error);
    }
  }

  // Valider le type MIME si des types sont spécifiés
  if (allowedMimeTypes.length > 0) {
    const typeValidation = await validateFileType(file.path, allowedMimeTypes);
    
    if (!typeValidation.valid) {
      throw new Error(typeValidation.error);
    }
  }

  return {
    valid: true,
    mimeType: allowedMimeTypes.length > 0 ? (await validateFileType(file.path, allowedMimeTypes)).mimeType : null,
    extension: allowedExtensions.length > 0 ? allowedExtensions[0] : path.extname(file.originalname).substring(1)
  };
}

module.exports = {
  validateFile,
  validateFileType,
  validateFileSignature
};