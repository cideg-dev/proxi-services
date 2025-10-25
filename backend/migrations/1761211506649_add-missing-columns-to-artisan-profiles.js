/* eslint-disable camelcase */

exports.shorthands = undefined;

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.up = (pgm) => {
  pgm.addColumns('artisan_profiles', {
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
    'langues_parlees',
    'assurance_professionnelle',
  ]);
};
