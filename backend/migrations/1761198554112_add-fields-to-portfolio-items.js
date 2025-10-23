/* eslint-disable camelcase */

exports.shorthands = undefined;

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.up = (pgm) => {
  // Rename 'caption' to 'description' and change its type to TEXT for longer content
  pgm.renameColumn('portfolio_items', 'caption', 'description');
  pgm.alterColumn('portfolio_items', 'description', {
    type: 'TEXT',
    using: 'description::TEXT', // Add this to cast existing data
  });

  // Add the new columns for name and price
  pgm.addColumns('portfolio_items', {
    name: {
      type: 'VARCHAR(255)',
      notNull: true,
      // We add a default value to avoid issues with existing rows
      default: 'Mon projet',
    },
    price: {
      type: 'NUMERIC(10, 2)', // Allows for prices up to 99,999,999.99
      notNull: false, // Price is optional (for artisans)
    },
  });

  // After adding the column with a default, we can remove the default
  // so that future entries must provide a name.
  pgm.alterColumn('portfolio_items', 'name', {
    default: null,
  });
};

/**
 * @param {import('node-pg-migrate').MigrationBuilder} pgm
 */
exports.down = (pgm) => {
  // Reverse the operations
  pgm.dropColumns('portfolio_items', ['name', 'price']);

  pgm.alterColumn('portfolio_items', 'description', {
    type: 'VARCHAR(255)',
    using: 'description::VARCHAR(255)',
  });
  pgm.renameColumn('portfolio_items', 'description', 'caption');
};