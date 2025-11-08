// Script de vérification de la structure de fichiers
const fs = require('fs');
const path = require('path');

console.log('=== Vérification de la structure de fichiers ===');

// Chemin absolu de ce fichier
const currentPath = __filename;
console.log('Chemin actuel:', currentPath);

// Chemin de la racine de backend
const backendRoot = path.resolve(__dirname, '..');
console.log('Racine de backend:', backendRoot);

// Vérification de la présence de db.config.js
const dbConfigPath = path.join(backendRoot, 'db.config.js');
const dbConfigExists = fs.existsSync(dbConfigPath);
console.log('db.config.js existe:', dbConfigExists);
console.log('Chemin db.config.js:', dbConfigPath);

// Vérification de la structure des dossiers
const srcPath = path.join(backendRoot, 'src');
const controllersPath = path.join(srcPath, 'controllers');
const routesPath = path.join(srcPath, 'routes');
const servicesPath = path.join(srcPath, 'services');

console.log('Dossier src existe:', fs.existsSync(srcPath));
console.log('Dossier controllers existe:', fs.existsSync(controllersPath));
console.log('Dossier routes existe:', fs.existsSync(routesPath));
console.log('Dossier services existe:', fs.existsSync(servicesPath));

if (fs.existsSync(controllersPath)) {
  const controllerFiles = fs.readdirSync(controllersPath);
  console.log('Fichiers dans controllers:', controllerFiles);
}

if (fs.existsSync(routesPath)) {
  const routeFiles = fs.readdirSync(routesPath);
  console.log('Fichiers dans routes:', routeFiles);
}

if (fs.existsSync(servicesPath)) {
  const serviceFiles = fs.readdirSync(servicesPath);
  console.log('Fichiers dans services:', serviceFiles);
}

console.log('=== Fin de la vérification ===');