#!/bin/bash

NAMESPACE=$1
BACKUP_NAME="${NAMESPACE}-backup-$(date +%Y%m%d-%H%M%S)"

if [ -z "$NAMESPACE" ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: $BACKUP_NAME
  namespace: openshift-adp
spec:
  includedNamespaces:
  - $NAMESPACE
  storageLocation: oadp-dpa-1
  ttl: 720h0m0s
EOF

echo "Backup '$BACKUP_NAME' created for namespace '$NAMESPACE'"
