# Filebeat Configuration

This directory contains the Filebeat configuration for container log collection.

## Components

- `filebeat.yaml`: DaemonSet configuration
- `filebeat-rbac.yaml`: RBAC and ServiceAccount configuration

## Configuration Details

Filebeat is configured to:
- Run as a DaemonSet on all nodes
- Collect container logs automatically
- Use autodiscovery for containers
- Process JSON logs
- Forward logs to Elasticsearch

### Log Collection

Default paths monitored:
- `/var/log/containers/`
- `/var/log/pods/`
- `/var/lib/docker/containers/`

## Security Requirements

Filebeat requires:
- Privileged SCC
- Host path access
- Service account with appropriate permissions

These are automatically configured by the deployment script.

## Resource Requirements

Each Filebeat pod uses:
- Memory: 200Mi (limit), 100Mi (request)
- CPU: 500m (limit), 100m (request)
