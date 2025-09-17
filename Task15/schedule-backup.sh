#!/bin/bash

NAMESPACE=$1
SCHEDULE=$2

if [ -z "$NAMESPACE" ] || [ -z "$SCHEDULE" ]; then
    echo "Usage: $0 <namespace> <cron-schedule>"
    echo "Example: $0 myapp '0 2 * * *'"
    exit 1
fi

cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: ${NAMESPACE}-scheduled-backup
  namespace: openshift-adp
spec:
  schedule: "$SCHEDULE"
  template:
    includedNamespaces:
    - $NAMESPACE
    storageLocation: default
    volumeSnapshotLocations:
    - default
    ttl: 720h0m0s
EOF

echo "Scheduled backup created for namespace '$NAMESPACE' with schedule '$SCHEDULE'"
