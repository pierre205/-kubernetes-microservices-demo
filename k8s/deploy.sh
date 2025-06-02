#!/bin/bash
set -e

echo "🚀 Déploiement Kubernetes Local - Microservices Demo"
echo "===================================================="

# Vérifier les prérequis
echo "🔍 Vérification des prérequis..."

# Vérifier Docker
if ! docker info &> /dev/null; then
    echo "❌ Docker n'est pas en cours d'exécution. Veuillez démarrer Docker Desktop."
    exit 1
fi

# Vérifier Kind
if ! command -v kind &> /dev/null; then
    echo "❌ Kind n'est pas installé."
    echo "💡 Installez-le avec : winget install Kubernetes.kind"
    exit 1
fi

# Créer le cluster Kind s'il n'existe pas
CLUSTER_NAME="microservices-demo"
if ! kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    echo "📦 Création du cluster Kind local..."
    kind create cluster --name $CLUSTER_NAME --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTER_NAME
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 9080
    protocol: TCP
  - containerPort: 443
    hostPort: 9443
    protocol: TCP
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
  - containerPort: 30002
    hostPort: 30002
    protocol: TCP
EOF
    echo "✅ Cluster Kind créé avec succès!"
else
    echo "✅ Cluster Kind '$CLUSTER_NAME' existe déjà"
fi

# Basculer vers le contexte Kind
echo "🔄 Basculement vers le contexte Kind..."
kubectl config use-context kind-$CLUSTER_NAME

# Vérifier la connexion
echo "🔍 Vérification de la connexion..."
kubectl cluster-info --context kind-$CLUSTER_NAME

# 1. Namespace
echo "📦 Création du namespace..."
kubectl apply -f namespace/

# 2. Secrets et ConfigMaps
echo "🔐 Configuration des secrets et configmaps..."
if [ -d "secrets/" ]; then
    kubectl apply -f secrets/
fi
if [ -d "configmaps/" ]; then
    kubectl apply -f configmaps/
fi

# 3. Base de données
echo "🗄️ Déploiement PostgreSQL..."
if [ -d "database/" ]; then
    kubectl apply -f database/
    
    # 4. Attendre que PostgreSQL soit prêt
    echo "⏳ Attente PostgreSQL..."
    kubectl wait --for=condition=ready pod -l app=postgres -n microservices-demo --timeout=300s
fi

# 5. Services
echo "🚀 Déploiement des microservices..."
if [ -d "services/" ]; then
    kubectl apply -f services/
fi

# 6. Ingress avec contrôleur NGINX pour Kind
echo "🌐 Installation du contrôleur Ingress NGINX..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Attendre que l'ingress controller soit prêt
echo "⏳ Attente du contrôleur Ingress..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 7. Appliquer l'ingress si il existe
if [ -f "ingress/ingress.yaml" ]; then
    echo "🌐 Configuration Ingress..."
    kubectl apply -f ingress/
fi

echo ""
echo "✅ Déploiement terminé !"
echo "================================================"
echo "📋 Statut des pods :"
kubectl get pods -n microservices-demo

echo ""
echo "🌐 Services exposés :"
kubectl get svc -n microservices-demo

echo ""
echo "🔗 Accès aux services :"
echo "  - Services via NodePort : http://localhost:30000, http://localhost:30001, etc."
echo "  - Services via Ingress : http://localhost:9080"
echo ""
echo "📊 Commandes utiles :"
echo "  - Logs PostgreSQL    : kubectl logs -f deployment/postgres -n microservices-demo"
echo "  - Logs User Service  : kubectl logs -f deployment/user-service -n microservices-demo"
echo "  - Tous les pods      : kubectl get pods -n microservices-demo -w"
echo "  - Port forwarding    : kubectl port-forward svc/user-service 3000:3000 -n microservices-demo"
echo ""
echo "🗑️  Pour supprimer :"
echo "  - Supprimer le cluster : kind delete cluster --name $CLUSTER_NAME"