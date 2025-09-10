#!/bin/bash

# OpenShift Cluster Troubleshooting Runner
# Usage: ./run-troubleshoot.sh [health-check|full-troubleshoot|remediate]

ACTION=${1:-health-check}

case $ACTION in
  "health-check")
    echo "Running health check..."
    ansible-playbook -i inventory health-check.yml
    ;;
  "full-troubleshoot")
    echo "Running full troubleshooting..."
    ansible-playbook -i inventory cluster-troubleshoot.yml
    ;;
  "remediate")
    echo "Running troubleshooting with remediation..."
    ansible-playbook -i inventory cluster-troubleshoot.yml -e remediate_nodes=true
    ;;
  *)
    echo "Usage: $0 [health-check|full-troubleshoot|remediate]"
    exit 1
    ;;
esac
