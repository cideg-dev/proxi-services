module.exports = {
  env: {
    commonjs: true,
    es2021: true,
    node: true,
  },
  extends: 'eslint:recommended',
  parserOptions: {
    ecmaVersion: 'latest',
  },
  rules: {
    'no-console': 'off', // Permet l'utilisation de console.log, utile pour un serveur Node.js
    'indent': ['error', 2], // Impose une indentation de 2 espaces
    'linebreak-style': ['error', 'windows'], // Utilise les fins de ligne Windows
    'quotes': ['error', 'single'], // Impose l'utilisation de guillemets simples
    'semi': ['error', 'always'], // Impose l'utilisation de points-virgules à la fin des instructions
  },
};
