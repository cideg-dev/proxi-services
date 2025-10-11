@echo off
echo "Running full setup and start..."

echo "Step 1: Installing dependencies..."
call install.bat
if %errorlevel% neq 0 (
    echo "Dependency installation failed. Exiting."
    pause
    exit /b %errorlevel%
)
pause

echo "Step 2: Initializing database..."
rem Ensure environment variables for DB are set before calling init_db.bat
rem Example: SET PGUSER=your_user & SET PGPASSWORD=your_password & SET PGDATABASE=your_db_name & SET PGHOST=localhost & SET PGPORT=5432
rem For a new developer, these should ideally be in a .env file and loaded by the backend.
rem For init_db.bat to work, they need to be set in the environment where it's called.
rem For now, assume the user sets them or they are default.
call backend\init_db.bat
if %errorlevel% neq 0 (
    echo "Database initialization failed. Exiting."
    pause
    exit /b %errorlevel%
)
pause

echo "Step 3: Starting backend and frontend..."
call start.bat
if %errorlevel% neq 0 (
    echo "Starting servers failed. Exiting."
    pause
    exit /b %errorlevel%
)

echo "Setup and start completed successfully."
pause
