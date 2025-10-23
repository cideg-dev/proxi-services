/* eslint-disable camelcase */

exports.shorthands = undefined;

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.up = (pgm) => {
  pgm.addColumns('users', {
    // This column will store the referral code of the user who referred this new user.
    referred_by: {
      type: 'VARCHAR(255)',
      nullable: true, // It's optional, not everyone will be referred.
    },
  });
};

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.down = (pgm) => {
  pgm.dropColumns('users', ['referred_by']);
};