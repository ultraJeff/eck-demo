# Elastic Stack (ECK) Templates for OpenShift

This directory contains the necessary templates to deploy the Elastic Stack (Elasticsearch, Kibana, and Filebeat) on OpenShift using ECK (Elastic Cloud on Kubernetes).

## Prerequisites

1. OpenShift cluster with ECK operator installed
2. Cluster admin access to create SecurityContextConstraints
3. Sufficient cluster resources for Elasticsearch (minimum 3 nodes)

## Components

1. `elasticsearch.yaml`: Defines a 3-node Elasticsearch cluster
2. `kibana.yaml`: Deploys Kibana connected to Elasticsearch
3. `filebeat.yaml`: Deploys Filebeat as a DaemonSet for log collection
4. `filebeat-scc.yaml`: SecurityContextConstraints for Filebeat
5. `kibana-route.yaml`: OpenShift route for Kibana access
6. `log-generator.yaml`: Demo application that generates sample logs

## Installation Order

1. Create the `eck-demo` namespace:
   ```bash
   oc create namespace eck-demo
   ```

2. Apply the Filebeat SCC:
   ```bash
   oc apply -f filebeat-scc.yaml
   ```

3. Deploy Elasticsearch:
   ```bash
   oc apply -f elasticsearch.yaml
   ```

4. Deploy Kibana (after Elasticsearch is ready):
   ```bash
   oc apply -f kibana.yaml
   ```

5. Create Kibana route:
   ```bash
   oc apply -f kibana-route.yaml
   ```

6. Deploy Filebeat:
   ```bash
   oc apply -f filebeat.yaml
   ```

7. Deploy the demo log generator:
   ```bash
   oc apply -f log-generator.yaml
   ```

## Accessing Kibana

1. Get the Kibana URL:
   ```bash
   oc get route kibana -n openshift-operators -o jsonpath='{.spec.host}'
   ```

2. Get the elastic user password:
   ```bash
   oc get secret elasticsearch-sample-es-elastic-user -n openshift-operators -o=jsonpath='{.data.elastic}' | base64 --decode
   ```

3. Log in with:
   - Username: elastic
   - Password: (from step 2)

## Filebeat Security

The Filebeat SCC provides the necessary permissions for log collection. It allows:
- Access to host log directories
- Running with specific user permissions
- Mounting required volumes

## Cleanup

To remove all components:
```bash
oc delete -f .
```

## To set up Kibana to visualize these logs:

1. Access Kibana using the URL:
   https://kibana-openshift-operators.apps.cluster-zqk9k.zqk9k.sandbox946.opentlc.com

2. Log in with:
•  Username: elastic
•  Password: (use the one we retrieved earlier)
3. Once logged in, follow these steps:
   a. Go to Menu → Stack Management → Data Views
   b. Click "Create data view"
   c. Set up the data view with:
◦  Name: "Filebeat Logs"
◦  Index pattern: "filebeat-*"
◦  Timestamp field: "@timestamp"
   d. Click "Save data view to Kibana"

4. To verify the setup:
   a. Go to Menu → Discover
   b. Select the "Filebeat Logs" data view
   c. You should see logs streaming in, including our log-generator entries

5. To create a basic dashboard:
   a. Go to Menu → Dashboard
   b. Click "Create dashboard"
   c. Add visualizations:
◦  Add a pie chart for log sources (container.name)
◦  Add a line graph showing log volume over time
◦  Add a data table showing the latest log messages

The logs should include our test application's output as well as system container logs. You can filter specifically for the log-generator by using the search:
This will demonstrate that:
1. Filebeat is collecting logs
2. Elasticsearch is storing them
3. Kibana can visualize them
4. The entire ELK stack is working end-to-end