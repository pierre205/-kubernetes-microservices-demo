#!/bin/bash
set -e

echo "🧹 Nettoyage Kubernetes - Microservices Demo"
echo "============================================="

# Supprimer le namespace (supprime tout)
kubectl delete namespace microservices-demo --ignore-not-found=true

# Attendre la suppression complète
echo "⏳ Attente suppression complète..."
kubectl wait --for=delete namespace/microservices-demo --timeout=120s

echo "✅ Nettoyage terminé !"
