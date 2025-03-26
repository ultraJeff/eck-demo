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
