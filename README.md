# Elastic Cloud on Kubernetes (ECK) Demo

This repository contains templates for deploying and configuring Elastic Cloud on Kubernetes (ECK) components.

## Directory Structure

- `templates/elasticsearch/`: Elasticsearch cluster configuration
- `templates/kibana/`: Kibana and routing configuration
- `templates/monitoring/`: Log collection and monitoring configuration
- `templates/apps/`: Demo applications

## Getting Started

1. Deploy Elasticsearch:
   ```bash
   oc apply -f templates/elasticsearch/elasticsearch.yaml
   ```

2. Deploy Kibana:
   ```bash
   oc apply -f templates/kibana/kibana.yaml
   oc apply -f templates/kibana/route.yaml
   ```

3. Set up monitoring:
   ```bash
   oc apply -f templates/monitoring/filebeat-scc.yaml
   oc apply -f templates/monitoring/filebeat.yaml
   ```

4. Deploy demo app:
   ```bash
   oc apply -f templates/apps/log-generator.yaml
   ```
