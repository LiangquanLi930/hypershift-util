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

platform=$(oc get infrastructure cluster -o=jsonpath='{.status.platformStatus.type}')
echo "platform: $platform"
if [ "$platform" == 'Azure' ]; then
    echo "=========================="
    echo "|| create cluster Azure ||"
    echo "=========================="

    clientId=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_client_id"|base64decode}}')
    clientSecret=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_client_secret"|base64decode}}')
    subscriptionId=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_subscription_id"|base64decode}}')
    tenantId=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_tenant_id"|base64decode}}')
    echo -e "subscriptionId: $subscriptionId\ntenantId: $tenantId\nclientId: $clientId\nclientSecret: $clientSecret" > config/azurecredentials
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
        --generate-ssh
elif [ "$platform" == "AWS" ]; then
    echo "=========================="
    echo "||  create cluster aws  ||"
    echo "=========================="

    accessKeyID=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_access_key_id"|base64decode}}')
    secureKey=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_secret_access_key"|base64decode}}')
    echo -e "[default]\naws_access_key_id=$accessKeyID\naws_secret_access_key=$secureKey" > config/awscredentials
    REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')
    echo "region: $REGION"

    hypershift create cluster aws \
        --aws-creds config/awscredentials \
        --pull-secret config/.dockerconfigjson \
        --name "$CLUSTER_NAME" \
        --base-domain qe.devcluster.openshift.com \
        --namespace "$NAMESPACE" \
        --node-pool-replicas 3 \
        --region "$REGION" \
        --generate-ssh
fi