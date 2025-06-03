#!/bin/bash

# 🧪 Script de Tests Microservices Kubernetes - VERSION CORRIGÉE
# ==============================================================

# Couleurs pour affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
NAMESPACE="microservices-demo"
API_GATEWAY_PORT=8090
USER_SERVICE_PORT=3001

# Fonctions utilitaires
print_header() {
    echo -e "\n${BLUE}$1${NC}"
    echo "=================================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Démarrage du script
echo -e "${BLUE}"
echo "🧪 TESTS MICROSERVICES KUBERNETES"
echo "================================="
echo -e "${NC}"

# Test de base pour voir si ça fonctionne
print_header "🔍 VÉRIFICATION DE BASE"
echo "Script démarré avec succès !"

# Vérifier kubectl
if command -v kubectl &> /dev/null; then
    print_success "kubectl disponible"
else
    print_error "kubectl non disponible"
    exit 1
fi

# Vérifier le namespace
if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_success "Namespace $NAMESPACE existe"
else
    print_error "Namespace $NAMESPACE n'existe pas"
    exit 1
fi

# Vérifier les pods
print_header "🚀 ÉTAT DES PODS"
kubectl get pods -n $NAMESPACE || {
    print_error "Impossible de récupérer les pods"
    exit 1
}

# Nettoyage des port-forwards existants
print_header "🧹 NETTOYAGE"
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2
print_success "Port-forwards nettoyés"

# Démarrer les port-forwards
print_header "🔌 DÉMARRAGE DES SERVICES"
kubectl port-forward svc/api-gateway $API_GATEWAY_PORT:80 -n $NAMESPACE &
kubectl port-forward svc/user-service $USER_SERVICE_PORT:3001 -n $NAMESPACE &

print_success "Services démarrés, attente 5 secondes..."
sleep 5

# Tests simples
print_header "🧪 TESTS BASIQUES"

echo -n "Test 1 - API Gateway Health: "
if curl -s http://localhost:$API_GATEWAY_PORT/health > /dev/null 2>&1; then
    print_success "OK"
else
    print_error "ÉCHEC"
fi

echo -n "Test 2 - API Gateway Users: "
if curl -s http://localhost:$API_GATEWAY_PORT/api/users > /dev/null 2>&1; then
    print_success "OK"
else
    print_error "ÉCHEC"
fi

echo -n "Test 3 - User Service Direct: "
if curl -s http://localhost:$USER_SERVICE_PORT/users > /dev/null 2>&1; then
    print_success "OK"
else
    print_error "ÉCHEC"
fi

# Afficher les réponses
print_header "📊 RÉPONSES DES SERVICES"

echo -e "\n${YELLOW}Health Check:${NC}"
curl -s http://localhost:$API_GATEWAY_PORT/health 2>/dev/null || echo "Connexion échouée"

echo -e "\n${YELLOW}Users via API Gateway:${NC}"
curl -s http://localhost:$API_GATEWAY_PORT/api/users 2>/dev/null || echo "Connexion échouée"

echo -e "\n${YELLOW}Users direct:${NC}"
curl -s http://localhost:$USER_SERVICE_PORT/users 2>/dev/null || echo "Connexion échouée"

# Nettoyage final
print_header "🎉 TERMINÉ"
pkill -f "kubectl port-forward" 2>/dev/null || true
print_success "Tests terminés et port-forwards nettoyés"

echo -e "\n${BLUE}Pour relancer manuellement:${NC}"
echo "kubectl port-forward svc/api-gateway 8090:80 -n microservices-demo &"
echo "kubectl port-forward svc/user-service 3001:3001 -n microservices-demo &"