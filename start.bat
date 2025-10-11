@echo off
start "Backend" cmd /c "npm run start:backend"
start "Frontend" cmd /c "npm run start:frontend || pause"
