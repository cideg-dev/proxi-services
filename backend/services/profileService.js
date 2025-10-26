const calculateProfileCompleteness = (profile, role) => {
  if (!profile) return 0;

  let totalFields = 0;
  let filledFields = 0;

  const checkField = (field) => {
    // Consider a field filled if it's not null, not undefined, and not an empty string.
    // For arrays (like languages), check if it's not empty.
    if (field !== null && field !== undefined && field !== '' && (!Array.isArray(field) || field.length > 0)) {
      filledFields++;
    }
  };

  if (role === 'client') {
    const fields = ['nom_complet', 'location', 'telephone', 'photo_url'];
    totalFields = fields.length;
    fields.forEach(field => checkField(profile[field]));
  } else if (role === 'artisan') {
    const fields = ['nom_complet', 'specialite', 'description', 'location', 'telephone', 'annees_experience', 'photo_url', 'horaires_ouverture', 'langues_parlees'];
    totalFields = fields.length;
    fields.forEach(field => checkField(profile[field]));
  } else if (role === 'commercant') {
    const fields = ['nom_entreprise', 'type_commerce', 'description', 'adresse', 'location', 'telephone', 'photo_url', 'horaires_ouverture', 'langues_parlees'];
    totalFields = fields.length;
    fields.forEach(field => checkField(profile[field]));
  }

  if (totalFields === 0) return 100; // Avoid division by zero
  return Math.round((filledFields / totalFields) * 100);
};

module.exports = { calculateProfileCompleteness };