#!/bin/bash
set -e

echo "🚀 Setting up Microservices Demo Development Environment"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs/postgres logs/backend logs/frontend
mkdir -p monitoring/grafana/dashboards
mkdir -p data/postgres data/redis

# Set permissions
chmod 755 logs/
chmod 755 data/

# Copy environment file
if [ ! -f .env ]; then
    cp .env.example .env
    echo "📝 Created .env file from example"
fi

# Install frontend dependencies locally (for development)
if [ -d "frontend" ]; then
    echo "📦 Installing frontend dependencies..."
    cd frontend
    npm install
    cd ..
fi

# Install backend dependencies locally (for development)
if [ -d "backend" ]; then
    echo "🔧 Installing backend dependencies..."
    cd backend
    npm install
    cd ..
fi

echo "✅ Development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "  1. Review .env file"
echo "  2. Run: make start"
echo "  3. Open: http://localhost:3000"
echo ""
