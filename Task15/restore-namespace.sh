#!/bin/bash

BACKUP_NAME=$1
RESTORE_NAME="${BACKUP_NAME}-restore-$(date +%Y%m%d-%H%M%S)"

if [ -z "$BACKUP_NAME" ]; then
    echo "Usage: $0 <backup-name>"
    echo "Available backups:"
    oc get backups -n openshift-adp --no-headers | awk '{print $1}'
    exit 1
fi

cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: $RESTORE_NAME
  namespace: openshift-adp
spec:
  backupName: $BACKUP_NAME
  restorePVs: true
EOF

echo "Restore '$RESTORE_NAME' created from backup '$BACKUP_NAME'"
