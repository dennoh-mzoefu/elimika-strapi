#!/bin/sh
set -ea

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
timeout=30
counter=0
until PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOST -U $DATABASE_USERNAME -d $DATABASE_NAME -c '\q' 2>/dev/null
do
  counter=$((counter+1))
  if [ $counter -gt $timeout ]; then
    echo "Error: Timed out waiting for PostgreSQL to be ready"
    exit 1
  fi
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done
echo "PostgreSQL is up and running!"

# Run database migrations
echo "Running database migrations..."
npm run strapi migrate

# Start Strapi in development mode for test environment
echo "Starting Strapi in development mode..."
exec "$@"