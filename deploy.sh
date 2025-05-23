#!/bin/bash

# ECK Stack Deployment Script
# This script deploys the full ECK stack (Elasticsearch, Kibana, and Filebeat)
# to a specified namespace with proper ordering and dependencies.

set -e

# Default values
NAMESPACE=${1:-monitoring}
TIMEOUT=60s

# Function to check if a resource exists
resource_exists() {
    local resource=$1
    local name=$2
    oc get $resource $name -n $NAMESPACE >/dev/null 2>&1
}

# Function to wait for resource readiness
wait_for_resource() {
    local resource=$1
    local name=$2
    local timeout=$3
    echo "Waiting for $resource/$name to be ready..."
    oc wait --for=jsonpath='{.status.health}'=green $resource/$name -n $NAMESPACE --timeout=$timeout
}

echo "Deploying ECK stack to namespace: $NAMESPACE"

# Create namespace if it doesn't exist
if ! oc get namespace $NAMESPACE >/dev/null 2>&1; then
    echo "Creating namespace $NAMESPACE..."
    oc create namespace $NAMESPACE
fi

# Deploy Elasticsearch
echo "Deploying Elasticsearch..."
cat templates/elasticsearch/elasticsearch.yaml | sed "s/namespace: monitoring/namespace: $NAMESPACE/g" | oc apply -f -

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready (this may take several minutes)..."
wait_for_resource "elasticsearch" "elasticsearch-sample" "$TIMEOUT"

# Deploy Elasticsearch route
echo "Deploying Elasticsearch route..."
cat templates/elasticsearch/route.yaml | sed "s/namespace: monitoring/namespace: $NAMESPACE/g" | oc apply -f -

# Deploy Kibana
echo "Deploying Kibana..."
cat templates/kibana/kibana.yaml | sed "s/namespace: monitoring/namespace: $NAMESPACE/g" | oc apply -f -

# Wait for Kibana to be ready
echo "Waiting for Kibana to be ready..."
wait_for_resource "kibana" "kibana-sample" "$TIMEOUT"

# Deploy Kibana route
echo "Deploying Kibana route..."
cat templates/kibana/route.yaml | sed "s/namespace: monitoring/namespace: $NAMESPACE/g" | oc apply -f -

# Set up Filebeat RBAC and SCC
echo "Setting up Filebeat RBAC and SecurityContextConstraints..."
cat templates/monitoring/filebeat-rbac.yaml | sed "s/namespace: monitoring/namespace: $NAMESPACE/g" | oc apply -f -

# TODO: Do this via oc apply filebeat-scc.yaml
oc adm policy add-scc-to-user privileged -z filebeat -n $NAMESPACE

# Deploy Filebeat
echo "Deploying Filebeat..."
cat templates/monitoring/filebeat.yaml | sed "s/namespace: monitoring/namespace: $NAMESPACE/g" | oc apply -f -

# Wait for Filebeat DaemonSet to be ready
echo "Waiting for Filebeat to be ready..."
wait_for_resource "beat" "filebeat" "$TIMEOUT"

# Final status check
echo -e "\nChecking deployment status:"
echo "Elasticsearch:"
oc get elasticsearch -n $NAMESPACE
echo -e "\nKibana:"
oc get kibana -n $NAMESPACE
echo -e "\nFilebeat:"
oc get beat -n $NAMESPACE

echo -e "\nDeployment complete! Here are the routes to access your services:"
oc get routes -n $NAMESPACE
