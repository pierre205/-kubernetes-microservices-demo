#!/bin/bash
echo "🚀 Starting microservices..."
docker-compose up -d

echo ""
echo "✅ Services started successfully!"
echo ""
echo "🌐 Available endpoints:"
echo "  Frontend:     http://localhost:3000"
echo "  Backend:      http://localhost:3001" 
echo "  Database:     localhost:5432"
echo "  Adminer:      http://localhost:8080"
echo "  Prometheus:   http://localhost:9090"
echo "  Grafana:      http://localhost:3001"
echo ""
echo "📋 Check status with: ./status.sh"
echo "📋 View logs with: ./logs.sh"
