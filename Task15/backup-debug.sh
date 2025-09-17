#!/bin/bash

NAMESPACE=$1
BACKUP_NAME="${NAMESPACE}-backup-$(date +%Y%m%d-%H%M%S)"

if [ -z "$NAMESPACE" ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

echo "Creating backup: $BACKUP_NAME"
echo "For namespace: $NAMESPACE"

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
echo "Checking status..."
sleep 5
oc get backup.velero.io $BACKUP_NAME -n openshift-adp -o jsonpath='{.status.phase}'
echo
echo "Full status:"
oc describe backup.velero.io $BACKUP_NAME -n openshift-adp
