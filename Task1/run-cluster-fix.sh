#!/bin/bash

# OpenShift Cluster Remediation Runner
# Usage: ./run-cluster-fix.sh [scan|remediate] [namespace]

ACTION=${1:-scan}
NAMESPACE=${2:-""}

case $ACTION in
  "scan")
    echo "Scanning cluster for issues..."
    ansible-playbook -i inventory cluster-scan.yml
    ;;
  "remediate")
    if [ -n "$NAMESPACE" ]; then
      echo "Remediating issues in namespace: $NAMESPACE"
      ansible-playbook -i inventory cluster-remediate.yml -e target_ns=$NAMESPACE
    else
      echo "Remediating all cluster issues..."
      ansible-playbook -i inventory cluster-remediate.yml
    fi
    ;;
  *)
    echo "Usage: $0 [scan|remediate] [namespace]"
    echo "Examples:"
    echo "  $0 scan                    # Scan entire cluster"
    echo "  $0 remediate              # Fix all issues"
    echo "  $0 remediate kube-system  # Fix issues in specific namespace"
    exit 1
    ;;
esac
