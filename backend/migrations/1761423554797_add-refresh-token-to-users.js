exports.up = pgm => {
  pgm.addColumn('users', {
    refresh_token: {
      type: 'text',
    }
  });
};

exports.down = pgm => {
  pgm.dropColumn('users', 'refresh_token');
};