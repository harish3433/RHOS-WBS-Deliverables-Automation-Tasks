# OADP Backup and Restore Guide

## Prerequisites
- OpenShift cluster with OADP operator installed
- Nooba/ODF storage configured
- Object bucket claim created

## Setup Cloud Credentials

### 1. Get credentials from existing bucket
```bash
export KUBECONFIG=/home/pc/openshift/kubeconfig
ACCESS_KEY=$(oc get secret oadp-backup-bucket -n openshift-adp -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
SECRET_KEY=$(oc get secret oadp-backup-bucket -n openshift-adp -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)
```

### 2. Create credentials file
```bash
cat > cloud-credentials <<EOF
[default]
aws_access_key_id=$ACCESS_KEY
aws_secret_access_key=$SECRET_KEY
EOF
```

### 3. Create secret
```bash
oc create secret generic cloud-credentials -n openshift-adp --from-file cloud=cloud-credentials
```

## Configure DataProtectionApplication (DPA)

### 1. Get bucket details
```bash
BUCKET_NAME=$(oc get configmap oadp-backup-bucket -n openshift-adp -o jsonpath='{.data.BUCKET_NAME}')
```

### 2. Create DPA configuration
```bash
cat > dpa-nooba.yaml <<EOF
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: oadp-dpa
  namespace: openshift-adp
spec:
  configuration:
    velero:
      defaultPlugins:
      - openshift
      - aws
    restic:
      enable: true
  backupLocations:
  - velero:
      provider: aws
      default: true
      credential:
        name: cloud-credentials
        key: cloud
      config:
        region: us-east-1
        s3Url: https://s3.openshift-storage.svc:443
        insecureSkipTLSVerify: "true"
        s3ForcePathStyle: "true"
      objectStorage:
        bucket: $BUCKET_NAME
        prefix: velero
EOF
```

### 3. Apply DPA
```bash
oc apply -f dpa-nooba.yaml
```

### 4. Verify Velero pods
```bash
oc get pods -n openshift-adp
```

## Backup Scripts

### backup-namespace.sh
```bash
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
```

### restore-namespace.sh
```bash
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
```

### schedule-backup.sh
```bash
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
    storageLocation: oadp-dpa-1
    ttl: 720h0m0s
EOF

echo "Scheduled backup created for namespace '$NAMESPACE' with schedule '$SCHEDULE'"
```

## Usage Commands

### Environment Setup
```bash
export KUBECONFIG=/home/pc/openshift/kubeconfig
cd /home/pc/openshift/noobabackup/test
chmod +x *.sh
```

### Create Backup
```bash
./backup-namespace.sh <namespace>
# Example: ./backup-namespace.sh default
```

### Check Backup Status
```bash
oc get backups.velero.io -n openshift-adp
oc get backup.velero.io <backup-name> -n openshift-adp -o jsonpath='{.status.phase}'
```

### Restore from Backup
```bash
./restore-namespace.sh <backup-name>
# Example: ./restore-namespace.sh default-backup-20250912-151736
```

### Check Restore Status
```bash
oc get restores.velero.io -n openshift-adp
oc describe restore.velero.io <restore-name> -n openshift-adp
```

### Schedule Automated Backups
```bash
# Daily at 2 AM
./schedule-backup.sh myapp '0 2 * * *'

# Every 6 hours
./schedule-backup.sh myapp '0 */6 * * *'

# Weekly on Sunday at 3 AM
./schedule-backup.sh myapp '0 3 * * 0'
```

### View Scheduled Backups
```bash
oc get schedules.velero.io -n openshift-adp
oc get backups.velero.io -n openshift-adp -l velero.io/schedule-name=<schedule-name>
```

## Testing Backup/Restore

### 1. Create Test Resources
```bash
oc create namespace test-backup
oc create deployment nginx --image=nginx -n test-backup
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: test-backup
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
```

### 2. Backup
```bash
./backup-namespace.sh test-backup
```

### 3. Delete Resources
```bash
oc delete deployment nginx -n test-backup
oc delete pvc test-pvc -n test-backup
```

### 4. Restore
```bash
./restore-namespace.sh <backup-name>
```

### 5. Verify
```bash
oc get all,pvc -n test-backup
```

## Common Cron Schedules
- `'0 2 * * *'` - Daily at 2 AM
- `'0 */12 * * *'` - Every 12 hours
- `'0 3 * * 0'` - Weekly on Sunday at 3 AM
- `'0 1 1 * *'` - Monthly on 1st at 1 AM

## Troubleshooting

### Check Velero Logs
```bash
oc logs -n openshift-adp deployment/velero
```

### Check DPA Status
```bash
oc get dpa -n openshift-adp
oc describe dpa oadp-dpa -n openshift-adp
```

### Check Storage Location
```bash
oc get backupstoragelocation -n openshift-adp
```

### Common Issues
- Backup stuck in `New` status = Velero not running
- `FailedValidation` = Storage location misconfigured
- No status = KUBECONFIG or permissions issue
