// Service pour le calcul de la complétude du profil

const calculateProfileCompleteness = (profileData, userRole) => {
  if (!profileData) return 0;
  
  let filledFields = 0;
  let totalFields = 0;

  // Déterminer les champs requis selon le rôle
  let requiredFields = [];
  
  switch(userRole) {
    case 'client':
      requiredFields = ['nom_complet', 'sexe'];
      break;
    case 'artisan':
      requiredFields = ['nom_complet', 'specialite', 'annees_experience'];
      break;
    case 'commercant':
      requiredFields = ['nom_entreprise', 'type_commerce', 'adresse', 'telephone'];
      break;
    default:
      return 0;
  }

  // Calculer les champs remplis
  totalFields = requiredFields.length;
  filledFields = requiredFields.filter(field => 
    profileData[field] && profileData[field].toString().trim() !== ''
  ).length;

  // Retourner le pourcentage de complétude
  return Math.round((filledFields / totalFields) * 100);
};

module.exports = {
  calculateProfileCompleteness
};