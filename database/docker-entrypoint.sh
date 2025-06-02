#!/bin/bash
set -e

echo "🗄️ Starting PostgreSQL for Microservices Demo..."
echo "📋 Database: $POSTGRES_DB"
echo "👤 User: $POSTGRES_USER"
echo "🕒 $(date)"

# Call the original entrypoint
exec docker-entrypoint.sh "$@"
