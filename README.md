# ECK Stack Deployment

This repository contains configurations and deployment scripts for setting up the Elastic Cloud on Kubernetes (ECK) stack on OpenShift.

## Components

- Elasticsearch: Distributed search and analytics engine
- Kibana: Data visualization dashboard
- Filebeat: Log collection and forwarding

## Prerequisites

1. OpenShift cluster with administrator access
2. OpenShift CLI (`oc`) installed and configured
3. ECK Operator installed in the cluster

## Directory Structure

```
.
├── deploy.sh                    # Main deployment script
├── templates
│   ├── elasticsearch/           # Elasticsearch configurations
│   ├── kibana/                  # Kibana configurations
│   └── monitoring/              # Filebeat configurations
```

## Deployment

1. Deploy to the default namespace (monitoring):
   ```bash
   ./deploy.sh
   ```

2. Deploy to a custom namespace:
   ```bash
   ./deploy.sh my-namespace
   ```

## Configuration Details

See the README files in each component directory for specific configuration details:

- [Elasticsearch Configuration](templates/elasticsearch/README.md)
- [Kibana Configuration](templates/kibana/README.md)
- [Filebeat Configuration](templates/monitoring/README.md)

## Index Lifecycle Management (ILM)

To set up ILM policies for automatic log rotation and cleanup:

1. Set up port forwarding to access Elasticsearch API:
   ```bash
   kubectl port-forward service/elasticsearch-sample-es-http -n monitoring 9200:9200
   ```

2. Create the ILM policy:
   ```bash
   curl -X PUT "https://localhost:9200/_ilm/policy/logs-ilm-policy" \
   -H "Content-Type: application/json" \
   -u "elastic:$ES_PASSWORD" \
   -k \
   -d '{
     "policy": {
       "phases": {
         "hot": {
           "min_age": "0ms",
           "actions": {
             "rollover": {
               "max_age": "7d",
               "max_size": "50gb"
             }
           }
         },
         "delete": {
           "min_age": "30d",
           "actions": {
             "delete": {}
           }
         }
       }
     }
   }'
   ```

3. Create the index template:
   ```bash
   curl -X PUT "https://localhost:9200/_index_template/logs-template" \
   -H "Content-Type: application/json" \
   -u "elastic:$ES_PASSWORD" \
   -k \
   -d '{
     "index_patterns": ["logs-*"],
     "template": {
       "settings": {
         "index.lifecycle.name": "logs-ilm-policy",
         "index.lifecycle.rollover_alias": "logs"
       }
     }
   }'
   ```

4. Create the initial index with rollover alias:
   ```bash
   curl -X PUT "https://localhost:9200/logs-000001" \
   -H "Content-Type: application/json" \
   -u "elastic:$ES_PASSWORD" \
   -k \
   -d '{
     "aliases": {
       "logs": {
         "is_write_index": true
       }
     }
   }'
   ```

This configuration will:
- Create new indices when the current one reaches 7 days or 50GB
- Delete indices after 30 days
- Automatically apply these settings to all indices matching the pattern "logs-*"

## Security Considerations

- Filebeat requires privileged access to read container logs
- Default passwords are generated automatically by the ECK operator
- To get the Elasticsearch password:
  ```bash
  oc get secret elasticsearch-sample-es-elastic-user -n <namespace> -o jsonpath='{.data.elastic}' | base64 -d
  ```

## Troubleshooting

1. Check pod status:
   ```bash
   oc get pods -n <namespace>
   ```

2. View component logs:
   ```bash
   # Elasticsearch
   oc logs -f -l elasticsearch.k8s.elastic.co/cluster-name=elasticsearch-sample -n <namespace>
   
   # Kibana
   oc logs -f -l kibana.k8s.elastic.co/name=kibana-sample -n <namespace>
   
   # Filebeat
   oc logs -f -l beat.k8s.elastic.co/name=filebeat -n <namespace>
   ```

3. Common issues:
   - If Filebeat fails to start, check if the SCC is properly configured
   - If components can't connect, verify the namespace matches in all configurations
