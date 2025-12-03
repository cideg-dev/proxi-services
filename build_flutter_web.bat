@echo off
echo Building Flutter Web application...

REM Change to the frontend directory
cd /d "E:\projet_services\frontend"

REM Get dependencies
flutter pub get

REM Build for web
flutter build web --release

echo Build completed. Output is in build/web directory.
pause