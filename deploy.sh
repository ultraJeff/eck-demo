#!/bin/bash

# ECK Stack Deployment Script
# This script deploys the full ECK stack (Elasticsearch, Kibana, and Filebeat)
# to a specified namespace with proper ordering and dependencies.

set -e

# Default values
NAMESPACE=${1:-monitoring}
TIMEOUT=120s

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

# Copy Elasticsearch credentials to llama-serve namespace for supergateway
echo "Copying Elasticsearch credentials to llama-serve namespace for supergateway..."
# Create llama-serve namespace if it doesn't exist
if ! oc get namespace llama-serve >/dev/null 2>&1; then
    echo "Creating namespace llama-serve..."
    oc create namespace llama-serve
fi

# Wait for the elastic user secret to be created
echo "Waiting for Elasticsearch elastic-user secret to be available..."
while ! oc get secret elasticsearch-sample-es-elastic-user -n $NAMESPACE >/dev/null 2>&1; do
    echo "Waiting for elasticsearch-sample-es-elastic-user secret..."
    sleep 5
done

# Delete existing secret if it exists
if oc get secret elasticsearch-sample-es-elastic-user -n llama-serve >/dev/null 2>&1; then
    echo "Deleting existing elasticsearch-sample-es-elastic-user secret in llama-serve namespace..."
    oc delete secret elasticsearch-sample-es-elastic-user -n llama-serve
fi

# Copy the secret from monitoring to llama-serve namespace
echo "Copying elasticsearch-sample-es-elastic-user secret to llama-serve namespace..."
ES_PASSWORD=$(oc get secret elasticsearch-sample-es-elastic-user -n $NAMESPACE -o jsonpath='{.data.elastic}')
oc create secret generic elasticsearch-sample-es-elastic-user --from-literal=elastic=$(echo $ES_PASSWORD | base64 -d) -n llama-serve
echo "Secret copied successfully!"

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

# Deploy Log Generator
echo "Deploying Log Generator..."
cat templates/apps/log-generator.yaml | sed "s/namespace: monitoring/namespace: $NAMESPACE/g" | oc apply -f -

# Final status check
echo -e "\nChecking deployment status:"
echo "Elasticsearch:"
oc get elasticsearch -n $NAMESPACE
echo -e "\nKibana:"
oc get kibana -n $NAMESPACE
echo -e "\nFilebeat:"
oc get beat -n $NAMESPACE
echo -e "\nLog Generator:"
oc get deployment log-generator -n $NAMESPACE
echo -e "\nDeployment complete! Here are the routes to access your services:"
oc get routes -n $NAMESPACE
