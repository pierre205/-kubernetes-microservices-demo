#!/bin/bash
echo "🚨 Emergency PostgreSQL fix..."

# 1. Complete stop and cleanup
echo "🛑 Stopping everything..."
docker-compose down
docker stop microservices-postgres 2>/dev/null || true
docker rm -f microservices-postgres 2>/dev/null || true

# 2. Remove all PostgreSQL volumes and data
echo "🧹 Cleaning volumes and data..."
docker volume rm microservices-postgres-data 2>/dev/null || true
docker volume rm kubernetes-microservices-demo_postgres-data 2>/dev/null || true
docker volume prune -f

# 3. Remove PostgreSQL images
echo "🗑️ Removing PostgreSQL images..."
docker rmi kubernetes-microservices-demo-postgres 2>/dev/null || true
docker rmi kubernetes-microservices-demo_postgres 2>/dev/null || true

# 4. Create minimal working PostgreSQL setup
echo "📁 Setting up minimal PostgreSQL..."
mkdir -p database/init

# Simple init script
cat > database/init/init.sql << 'SQL_EOF'
CREATE DATABASE microservices_db;
\c microservices_db;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE users (id SERIAL PRIMARY KEY, email VARCHAR(255), name VARCHAR(255));
INSERT INTO users (email, name) VALUES ('test@example.com', 'Test User');
SQL_EOF

# Minimal Dockerfile
cat > database/Dockerfile << 'DOCKER_EOF'
FROM postgres:15-alpine

ENV POSTGRES_DB=postgres
ENV POSTGRES_USER=postgres  
ENV POSTGRES_PASSWORD=postgres

COPY init/ /docker-entrypoint-initdb.d/

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U postgres || exit 1

EXPOSE 5432
DOCKER_EOF

# 5. Ensure docker-compose has correct PostgreSQL config  
echo "📝 Updating docker-compose.yml..."

# Backup current docker-compose
cp docker-compose.yml docker-compose.yml.backup

# Update PostgreSQL service in docker-compose.yml
cat > temp-postgres-service.yml << 'TEMP_EOF'
  postgres:
    build: 
      context: ./database
      dockerfile: Dockerfile
    container_name: microservices-postgres
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - microservices
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
TEMP_EOF

# Remove existing postgres service and add new one
sed -i '/^[[:space:]]*postgres:/,/^[[:space:]]*[a-zA-Z]/{ /^[[:space:]]*[a-zA-Z]/!d; }' docker-compose.yml

# Add the correct postgres service
if ! grep -q "^services:" docker-compose.yml; then
    echo "services:" >> docker-compose.yml
fi

cat temp-postgres-service.yml >> docker-compose.yml

# Ensure volumes section exists
if ! grep -q "^volumes:" docker-compose.yml; then
    echo "" >> docker-compose.yml
    echo "volumes:" >> docker-compose.yml
fi

if ! grep -q "postgres-data:" docker-compose.yml; then
    echo "  postgres-data:" >> docker-compose.yml
fi

# Ensure networks section exists
if ! grep -q "^networks:" docker-compose.yml; then
    echo "" >> docker-compose.yml
    echo "networks:" >> docker-compose.yml
fi

if ! grep -q "microservices:" docker-compose.yml; then
    echo "  microservices:" >> docker-compose.yml
    echo "    driver: bridge" >> docker-compose.yml
fi

# Cleanup temp file
rm temp-postgres-service.yml

echo "✅ docker-compose.yml updated"

# 6. Build PostgreSQL from scratch
echo "🔨 Building PostgreSQL..."
docker-compose build --no-cache postgres

# 7. Start PostgreSQL alone first
echo "🚀 Starting PostgreSQL..."
docker-compose up -d postgres

echo "⏳ Monitoring PostgreSQL startup..."
for i in {1..20}; do
    echo "--- Attempt $i/20 ($(date)) ---"
    
    # Check container status
    STATUS=$(docker inspect microservices-postgres --format='{{.State.Status}}' 2>/dev/null || echo "not-found")
    echo "Container status: $STATUS"
    
    if [ "$STATUS" = "running" ]; then
        # Check if PostgreSQL is responding
        if docker-compose exec -T postgres pg_isready -U postgres 2>/dev/null; then
            echo "✅ PostgreSQL is ready!"
            break
        else
            echo "❌ PostgreSQL not ready yet..."
        fi
    else
        echo "❌ Container not running. Recent logs:"
        docker-compose logs --tail=5 postgres | sed 's/^/   /'
    fi
    
    sleep 15
done

# 8. Final verification
echo ""
echo "🧪 === FINAL VERIFICATION ==="
echo "Container status:"
docker-compose ps postgres

echo ""
echo "PostgreSQL logs (last 10 lines):"
docker-compose logs --tail=10 postgres

echo ""
echo "Connection test:"
if docker-compose exec -T postgres psql -U postgres -c "SELECT version();" 2>/dev/null; then
    echo "✅ PostgreSQL connection works!"
    
    echo ""
    echo "Database test:"
    docker-compose exec -T postgres psql -U postgres -c "\l" | grep microservices || echo "Creating microservices_db..."
    docker-compose exec -T postgres psql -U postgres -c "CREATE DATABASE microservices_db;" 2>/dev/null || echo "Database might already exist"
    
    echo ""
    echo "✅ PostgreSQL is healthy and ready!"
    echo ""
    echo "📋 Connection details:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  User: postgres"
    echo "  Password: postgres"
    echo "  Database: microservices_db"
    echo ""
    echo "🎉 Ready to start other services:"
    echo "  docker-compose up -d"
    
else
    echo "❌ PostgreSQL connection still failing"
    echo ""
    echo "🔍 Troubleshooting info:"
    docker-compose logs postgres
    exit 1
fi
