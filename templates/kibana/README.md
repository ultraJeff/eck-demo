# Kibana Configuration

This directory contains the Kibana configuration for the ECK stack.

## Configuration Details

The `kibana.yaml` file defines:
- Single Kibana instance
- Automatic Elasticsearch connection
- Default security settings

## Security

- Uses Elasticsearch credentials automatically
- Access via OpenShift route
- Authentication required (uses Elasticsearch credentials)

## Resource Requirements

Default resources:
- Memory: 1Gi
- CPU: 1

Adjust these values in `kibana.yaml` based on your needs.

Then run `oc get secret -n monitoring elasticsearch-sample-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d` to get the elastic user password.
