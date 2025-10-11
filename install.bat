@echo off
echo "Installing root dependencies..."
npm install
echo "Installing backend dependencies..."
cd backend
npm install
cd ..
echo "Installing frontend dependencies..."
cd frontend
flutter pub get
cd ..
echo "All dependencies installed."
