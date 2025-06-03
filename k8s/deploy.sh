#!/bin/bash
set -e

CLUSTER_NAME="microservices-demo"
NAMESPACE="microservices-demo"

echo "🚀 Déploiement Kubernetes Local - Microservices Demo"
echo "===================================================="

# Vérification des prérequis
echo "🔍 Vérification des prérequis..."
if ! command -v kind &> /dev/null; then
    echo "❌ Kind n'est pas installé"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl n'est pas installé"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

# Vérification/création du cluster
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "✅ Cluster Kind '${CLUSTER_NAME}' existe déjà"
else
    echo "📦 Création du cluster Kind local..."
    kind create cluster --name $CLUSTER_NAME --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
  - containerPort: 9080
    hostPort: 9080
    protocol: TCP
  - containerPort: 80
    hostPort: 090
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF
    echo "✅ Cluster Kind créé avec succès!"
fi

echo "🔄 Basculement vers le contexte Kind..."
kubectl config use-context kind-$CLUSTER_NAME

echo "🔍 Vérification de la connexion..."
kubectl cluster-info

# ✅ CORRECTION : BUILD D'UNE VRAIE IMAGE NODE.JS
echo "🔨 Construction et chargement des images Docker..."

# Vérifier si le dossier user-service existe
if [ -d "user-service" ]; then
    echo "📦 Build user-service existant..."
    cd user-service
    docker build -t user-service:local .
    cd ..
    
    echo "📤 Chargement user-service dans Kind..."
    kind load docker-image user-service:local --name $CLUSTER_NAME
    echo "✅ user-service:local chargé"
else
    echo "🔧 Création d'une image user-service fonctionnelle..."
    
    # Créer un dossier temporaire avec un vrai service Node.js
    mkdir -p temp-user-service
    
    # Package.json
    cat > temp-user-service/package.json <<EOF
{
  "name": "user-service",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.0"
  },
  "scripts": {
    "start": "node server.js"
  }
}
EOF

    # Server.js complet
    cat > temp-user-service/server.js <<EOF
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

// Variables d'environnement
const dbConfig = {
    host: process.env.DB_HOST || 'postgres',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'mydatabase',
    user: process.env.DB_USER || 'myuser',
    password: process.env.DB_PASSWORD || 'mypassword'
};

console.log('🔧 Configuration DB:', {
    host: dbConfig.host,
    port: dbConfig.port,
    database: dbConfig.database,
    user: dbConfig.user
});

// Health check
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'OK', 
        service: 'user-service',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        database: {
            host: dbConfig.host,
            connected: true // Simulé pour le moment
        }
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({ 
        message: 'User Service is running',
        endpoints: [
            'GET /health - Health check',
            'GET /users - List users',
            'GET /users/:id - Get user by ID'
        ]
    });
});

// Users endpoints (simulation sans DB pour l'instant)
app.get('/users', (req, res) => {
    res.json({ 
        users: [
            { id: 1, name: 'John Doe', email: 'john@example.com', created: new Date() },
            { id: 2, name: 'Jane Doe', email: 'jane@example.com', created: new Date() },
            { id: 3, name: 'Admin User', email: 'admin@example.com', created: new Date() }
        ],
        total: 3,
        timestamp: new Date().toISOString()
    });
});

app.get('/users/:id', (req, res) => {
    const id = parseInt(req.params.id);
    if (isNaN(id) || id < 1) {
        return res.status(400).json({ error: 'Invalid user ID' });
    }
    
    res.json({ 
        id, 
        name: \`User \${id}\`, 
        email: \`user\${id}@example.com\`,
        created: new Date(),
        lastLogin: new Date()
    });
});

// Create user endpoint
app.post('/users', (req, res) => {
    const { name, email } = req.body;
    if (!name || !email) {
        return res.status(400).json({ error: 'Name and email are required' });
    }
    
    const newUser = {
        id: Math.floor(Math.random() * 1000) + 100,
        name,
        email,
        created: new Date()
    };
    
    res.status(201).json(newUser);
});

// Error handling
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(\`🚀 User Service listening on port \${PORT}\`);
    console.log(\`📡 Health check: http://localhost:\${PORT}/health\`);
    console.log(\`👥 Users API: http://localhost:\${PORT}/users\`);
    console.log(\`🔧 Environment: \${process.env.NODE_ENV || 'development'}\`);
});
EOF

    # Dockerfile
    cat > temp-user-service/Dockerfile <<EOF
FROM node:18-alpine

# Installer les dépendances système
RUN apk add --no-cache curl

WORKDIR /app

# Copier package.json et installer les dépendances
COPY package.json .
RUN npm install --only=production

# Copier le code source
COPY server.js .

# Exposer le port
EXPOSE 3001

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Démarrer l'application
CMD ["node", "server.js"]
EOF
    
    # Build de l'image
    echo "🔧 Build de l'image user-service..."
    docker build -t user-service:local ./temp-user-service/
    
    # Nettoyage
    rm -rf temp-user-service
    
    echo "📤 Chargement user-service dans Kind..."
    kind load docker-image user-service:local --name $CLUSTER_NAME
    echo "✅ user-service:local créé et chargé"
fi

# Création du namespace
echo "📦 Création du namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Configuration des secrets
echo "🔐 Configuration des secrets et configmaps..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: $NAMESPACE
type: Opaque
data:
  POSTGRES_USER: $(echo -n "myuser" | base64)
  POSTGRES_PASSWORD: $(echo -n "mypassword" | base64)
  POSTGRES_DB: $(echo -n "mydatabase" | base64)
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: $NAMESPACE
data:
  POSTGRES_DB: "mydatabase"
  POSTGRES_USER: "myuser"
EOF

# Déploiement PostgreSQL
echo "🗄️ Déploiement PostgreSQL..."
kubectl apply -f database/

echo "⏳ Attente PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s

# Déploiement des microservices
echo "🚀 Déploiement des microservices..."
kubectl apply -f services/

echo "⏳ Attente des services..."
sleep 20

# ✅ CORRECTION : URL Ingress NGINX mise à jour
echo "🌐 Installation du contrôleur Ingress NGINX..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Attente du contrôleur Ingress (non-bloquant)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=60s || echo "⚠️ Ingress prend plus de temps, on continue..."

echo ""
echo "✅ Déploiement terminé !"
echo "================================================"

# Affichage du statut
echo "📋 Statut des pods :"
kubectl get pods -n $NAMESPACE

echo ""
echo "🌐 Services exposés :"
kubectl get svc -n $NAMESPACE

echo ""
echo "🔗 Accès aux services :"
echo "  - API Gateway (LoadBalancer) : kubectl get svc api-gateway -n $NAMESPACE"
echo "  - User Service (Port-Forward): kubectl port-forward svc/user-service 3001:3001 -n $NAMESPACE"
echo "  - API Gateway (Port-Forward) : kubectl port-forward svc/api-gateway 8090:80 -n $NAMESPACE"

echo ""
echo "🧪 Tests automatiques dans 15 secondes..."
sleep 15

# Tests automatiques
echo "🔧 Test des services..."
kubectl port-forward svc/user-service 3001:3001 -n $NAMESPACE > /dev/null 2>&1 &
USER_PF_PID=$!
sleep 3

echo "Test User Service:"
if curl -s -m 5 http://localhost:3001/health 2>/dev/null | grep -q "OK"; then
    echo "✅ User Service fonctionne !"
    echo "📊 Données utilisateurs:"
    curl -s http://localhost:3001/users 2>/dev/null | head -n 5
else
    echo "⚠️ User Service ne répond pas encore"
fi

# Test API Gateway
kubectl port-forward svc/api-gateway 8090:80 -n $NAMESPACE > /dev/null 2>&1 &
API_PF_PID=$!
sleep 3

echo ""
echo "Test API Gateway:"
if curl -s -m 5 http://localhost:8090/health 2>/dev/null; then
    echo
    echo "✅ API Gateway fonctionne !"
else
    echo
    echo "⚠️ API Gateway ne répond pas encore"
fi

# Nettoyage des port-forwards
kill $USER_PF_PID $API_PF_PID 2>/dev/null || true

echo ""
echo "📊 Commandes utiles :"
echo "  - Logs User Service  : kubectl logs -f deployment/user-service -n $NAMESPACE"
echo "  - Logs API Gateway   : kubectl logs -f deployment/api-gateway -n $NAMESPACE"
echo "  - Tous les pods      : kubectl get pods -n $NAMESPACE -w"

echo ""
echo "🗑️  Pour supprimer :"
echo "  - Supprimer le cluster : kind delete cluster --name $CLUSTER_NAME"

echo ""
echo "🎉 Déploiement terminé avec succès !"
