#!/bin/bash
set -e

echo "🗄️ Starting PostgreSQL for Microservices Demo..."
echo "📋 Database: $POSTGRES_DB"
echo "👤 User: $POSTGRES_USER"
echo "🕒 $(date)"

# CORRECTION: Appel du vrai entrypoint PostgreSQL avec chemin complet
exec /usr/local/bin/docker-entrypoint.sh "$@"
