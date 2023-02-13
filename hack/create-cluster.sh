#!/bin/bash
echo -n "cluster name?"
read -r CLUSTER_NAME
echo -n "namespace? (default:clusters)"
read -r NAMESPACE

if [ ! -n "$NAMESPACE" ]; then
    NAMESPACE="clusters"
fi

echo "extract secret/pull-secret"
oc extract secret/pull-secret -n openshift-config --to=config --confirm
PLAYLOADIMAGE=$(oc get clusterversion version -ojsonpath='{.status.desired.image}')
echo "playload image: $PLAYLOADIMAGE"

platform=$(oc get infrastructure cluster -o=jsonpath='{.status.platformStatus.type}')
bash "hack/export-credentials.sh" "$platform"
if [ "$platform" == 'Azure' ]; then
    echo "=========================="
    echo "|| create cluster Azure ||"
    echo "=========================="

    location=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')
    echo "location: $location"

    hypershift create cluster azure \
        --azure-creds config/azurecredentials \
        --pull-secret config/.dockerconfigjson \
        --name "$CLUSTER_NAME" \
        --base-domain qe.azure.devcluster.openshift.com \
        --namespace "$NAMESPACE" \
        --location "$location" \
        --node-pool-replicas 3 \
        --release-image "$PLAYLOADIMAGE" \
        --control-plane-operator-image "registry.ci.openshift.org/ocp/4.12:hypershift-operator" \
        --generate-ssh
elif [ "$platform" == "AWS" ]; then
    echo "=========================="
    echo "||  create cluster aws  ||"
    echo "=========================="

    REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')
    echo "region: $REGION"

    PLAYLOADIMAGE=$(oc get clusterversion version -ojsonpath='{.status.desired.image}')
    hypershift create cluster aws \
        --aws-creds config/awscredentials \
        --pull-secret config/.dockerconfigjson \
        --name "$CLUSTER_NAME" \
        --base-domain qe.devcluster.openshift.com \
        --namespace "$NAMESPACE" \
        --node-pool-replicas 3 \
        --region "$REGION" \
        --control-plane-availability-policy HighlyAvailable \
        --infra-availability-policy HighlyAvailable \
        --control-plane-operator-image "registry.ci.openshift.org/ocp/4.12:hypershift-operator" \
        --release-image "$PLAYLOADIMAGE" \
        --generate-ssh
else
  echo ""
fi