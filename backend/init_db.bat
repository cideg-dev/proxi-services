@ECHO OFF
REM Use environment variables for PostgreSQL connection details
SET PGUSER=%PGUSER%
SET PGHOST=%PGHOST%
SET PGPORT=%PGPORT%
SET PGDATABASE=%PGDATABASE%

ECHO "Configuring database: %PGDATABASE%"

REM Temporarily unset PGDATABASE to ensure connection to 'postgres' for DROP/CREATE
SET PGDATABASE_TEMP=%PGDATABASE%
SET PGDATABASE=

psql -w -U %PGUSER% -h %PGHOST% -p %PGPORT% -d postgres -c "DROP DATABASE IF EXISTS %PGDATABASE_TEMP%;"
psql -w -U %PGUSER% -h %PGHOST% -p %PGPORT% -d postgres -c "CREATE DATABASE %PGDATABASE_TEMP%;"

REM Restore PGDATABASE for schema application
SET PGDATABASE=%PGDATABASE_TEMP%
SET PGDATABASE_TEMP=

psql -w -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -f backend\schema.sql

ECHO "Database configured successfully."
