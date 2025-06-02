#!/bin/bash
echo "🛠️ Setting up development environment..."

# Create directories
mkdir -p logs/postgres logs/backend logs/frontend
mkdir -p monitoring/grafana/dashboards
mkdir -p data/postgres data/redis

# Set permissions
chmod 755 logs/ data/ 2>/dev/null || true

# Create .env file
cat > .env << 'EOF'
# Application
NODE_ENV=development
PORT=3001

# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=microservices_db
DB_USER=postgres
DB_PASSWORD=postgres123

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redis123

# Monitoring
PROMETHEUS_URL=http://prometheus:9090
GRAFANA_ADMIN_PASSWORD=admin123

# Docker Registry
DOCKER_REGISTRY=your-registry.com
IMAGE_TAG=latest
EOF

echo "✅ Setup complete!"
echo ""
echo "🚀 Next commands:"
echo "  ./build.sh     # Build images"
echo "  ./start.sh     # Start services"
echo "  ./status.sh    # Check status"
