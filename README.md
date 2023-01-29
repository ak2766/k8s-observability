# k8s-observability
Deploy prometheus, promtail, and loki to your cluster

# Installation
Follow these steps to deploy the stack in your cluster:

## Clone this repo to `/opt/k8s-observability` as the BASH script depends on this directory structure
  $ cd /opt
  $ git clone https://github.com/ak2766/k8s-observability.git
  $ cd k8s-observability

## Customize files to suit your environment
Modify the following files and ensure all `CHANGEME` occurrences are configure for your environment:
  * Loki:   `./values/loki-distributed-values.yaml`
  * Script: `./scripts/loki.sh`

## Deploy to cluster
  $ ./scripts/lokiup

# Access Grafana
You'll need to make use of k8s port-forward for this.

## Port-forward Grafana service
  $ kubectl -n monitoring port-forward service/prom-grafana 3000:80

## Access Grafana UI
  https://127.0.0.1:3000

## Login using the following credentials
  * User:     kubectl -n monitoring get secrets prom-grafana -o jsonpath='{.data.admin-user}' | base64 -d
  * Password: kubectl -n monitoring get secrets prom-grafana -o jsonpath='{.data.admin-password}' | base64 -d


