#!/bin/bash

getPrometheusLokiPromtail() { #{{{
  # ensure helm is installed
  [[ $(command -v helm) ]] || { echo "Please install helm"; exit 2; }
  # ensure helm repos are installed
  promcomm=$(helm repo list | awk '/prometheus-community.github.io/{print $1}')
  if [[ ${promcomm} == "" ]]; then
    echo "Please add prometheus-community helm repo:"
    echo "  Hint: helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update"
    exit 2
  fi
  lokiprom=$(helm repo list | awk '/grafana.github.io/{print $1}')
  if [[ ${promcomm} == "" ]]; then
    echo "Please add grafana helm repo:"
    echo "  Hint: helm repo add grafana https://grafana.github.io/helm-charts && helm repo update"
    exit 2
  fi
  # now that all helm prerequisites have been met, let's get the artifacts
  [[ ! -s kube-prometheus-stack-40.1.2.tgz ]] && helm pull ${promcomm}/kube-prometheus-stack --version 40.1.2
  [[ ! -s loki-distributed-0.58.0.tgz ]] && helm pull ${lokiprom}/loki-distributed --version 0.58.0
  [[ ! -s promtail-6.4.0.tgz ]] && helm pull ${lokiprom}/promtail --version 6.4.0
} #}}}

########
# MAIN #
########

### BEGIN - Ensure these are correct before proceeding ###
export KUBECONFIG="CHANGEME"
workingDir="/opt/k8s-observability"
### END ###

if [[ ! -s ${KUBECONFIG} ]]; then
  echo -e "\n[1;31mCannot proceed until all variables in script are setup. Exiting[0m"
  echo -e "Ensure that KUBECONFIG points to the correct location for your cluster.\n"
  exit 1
fi
calledas="$(basename $(echo ${BASH_SOURCE[0]} | perl -pe 's/loki//'))"
[[ ! -d ${workingDir} ]] && mkdir -p ${workingDir}
ns="monitoring"
pushd ${workingDir} &>/dev/null
getPrometheusLokiPromtail
case ${calledas} in
  up)
    [[ ! -s values/kube-prometheus-stack-values.yaml ]] && { echo "Values file for kube-prometheus-stack not found."; exit 3; }
    [[ ! -s values/promtail-values.yaml ]] && { echo "Values file for promtail not found."; exit 3; }
    [[ ! -s values/loki-distributed-values.yaml ]] && { echo "Values file for loki-distributed not found."; exit 3; }
    #[[ ! -s /etc/.s3k8saws ]] && { echo "Could not find AWS credentials."; exit 3; }
    kubectl create ns ${ns}
    helm upgrade --install -n ${ns} --create-namespace prom ${workingDir}/kube-prometheus-stack-40.1.2.tgz -f ${workingDir}/values/kube-prometheus-stack-values.yaml --wait
    helm upgrade --install -n ${ns} --create-namespace promtail ${workingDir}/promtail-6.4.0.tgz -f ${workingDir}/values/promtail-values.yaml --wait
    helm upgrade --install -n ${ns} --create-namespace loki ${workingDir}/loki-distributed-0.58.0.tgz -f ${workingDir}/values/loki-distributed-values.yaml --wait
    kubectl -n ${ns} get all
    ;;
  down)
    helm uninstall -n ${ns} loki --wait
    helm uninstall -n ${ns} promtail --wait
    helm uninstall -n ${ns} prom --wait
    kubectl delete ns ${ns}
    ;;
esac
popd &>/dev/null
