# Elasticsearch Configuration

This directory contains the Elasticsearch configuration for the ECK stack.

## Configuration Details

The `elasticsearch.yaml` file defines:
- A basic Elasticsearch cluster
- 3 node configuration
- Default storage settings
- Security enabled by default

## Storage Configuration

By default, the configuration uses:
- Storage class: gp2
- Storage size: 50Gi per node

Modify the storage settings in `elasticsearch.yaml` if needed.

## Security

- Authentication is enabled by default
- Credentials are automatically generated
- Get the elastic user password:
  ```bash
  oc get secret elasticsearch-sample-es-elastic-user -n <namespace> -o jsonpath='{.data.elastic}' | base64 -d
  ```

## Resource Requirements

Each Elasticsearch node requires:
- Memory: 4Gi
- CPU: 2

Adjust these values in `elasticsearch.yaml` based on your needs.
