#!/bin/bash

# Development startup script for Acquisition App with Neon Local
# This script starts the application in development mode with Neon Local

set -euo pipefail

echo "🚀 Starting Acquisition App in Development Mode"
echo "================================================"

# Check if .env.development exists
if [ ! -f .env.development ]; then
    echo "❌ Error: .env.development file not found!"
    echo "   Please copy .env.development from the template and update with your Neon credentials."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "   Please start Docker Desktop and try again."
    exit 1
fi

# Create .neon_local directory if it doesn't exist
mkdir -p .neon_local

# Add .neon_local to .gitignore if not already present
if ! grep -q ".neon_local/" .gitignore 2>/dev/null; then
    echo ".neon_local/" >> .gitignore
    echo "✅ Added .neon_local/ to .gitignore"
fi

echo "📦 Building and starting development containers (detached)..."
echo "   - Neon Local proxy will create an ephemeral database branch"
echo "   - Application will run with hot reload enabled"
echo ""

# Start the stack in detached mode first so we can run migrations inside the container
docker compose -f docker-compose.dev.yml up -d --build

# Wait for Neon Local to be healthy
echo "⏳ Waiting for Neon Local health..."
NEON_CID=$(docker compose -f docker-compose.dev.yml ps -q neon-local)
if [ -z "$NEON_CID" ]; then
  echo "❌ Failed to find neon-local container"
  exit 1
fi

for i in {1..30}; do
  STATUS=$(docker inspect -f '{{.State.Health.Status}}' "$NEON_CID" 2>/dev/null || echo "starting")
  if [ "$STATUS" = "healthy" ]; then
    break
  fi
  sleep 2
  if [ "$i" -eq 30 ]; then
    echo "❌ neon-local did not become healthy in time"
    exit 1
  fi
done

# Run migrations inside the app container (uses .env.development)
echo "📜 Applying latest schema with Drizzle (in container)..."
docker compose -f docker-compose.dev.yml run --rm app npm run db:migrate

# Follow application logs
echo ""
echo "🎉 Development environment started!"
echo "   Application: http://localhost:3000"
echo "   Database (Neon Local): postgres://user:password@localhost:5432/postgres"
echo ""
echo "To stop the environment, press Ctrl+C or run: docker compose -f docker-compose.dev.yml down"

docker compose -f docker-compose.dev.yml logs -f app
