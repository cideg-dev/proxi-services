/* eslint-disable camelcase */

exports.shorthands = undefined;

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.up = (pgm) => {
  pgm.addColumns('artisan_profiles', {
    siret: {
      type: 'VARCHAR(14)',
      nullable: true,
    },
    site_web: {
      type: 'VARCHAR(255)',
      nullable: true,
    },
    photo_url: {
      type: 'VARCHAR(255)',
      nullable: true,
    },
    document_verification_url: {
      type: 'VARCHAR(255)',
      nullable: true,
    },
    verification_status: {
      type: 'VARCHAR(50)',
      notNull: true,
      default: 'not_verified',
    },
    horaires_ouverture: {
      type: 'TEXT',
      nullable: true,
    },
    langues_parlees: {
      type: 'TEXT[]',
      nullable: true,
      default: pgm.func('ARRAY[]::TEXT[]'),
    },
    assurance_professionnelle: {
      type: 'BOOLEAN',
      notNull: true,
      default: false,
    },
  });
};

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.down = (pgm) => {
  pgm.dropColumns('artisan_profiles', [
    'siret',
    'site_web',
    'photo_url',
    'document_verification_url',
    'verification_status',
    'horaires_ouverture',
    'langues_parlees',
    'assurance_professionnelle',
  ]);
};