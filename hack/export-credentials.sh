#!/bin/bash

PLATFORM=$(oc get infrastructure cluster -o=jsonpath='{.status.platformStatus.type}')
echo "$PLATFORM export credentials"
if [ "$PLATFORM" == 'Azure' ]; then
    clientId=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_client_id"|base64decode}}')
    clientSecret=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_client_secret"|base64decode}}')
    subscriptionId=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_subscription_id"|base64decode}}')
    tenantId=$(oc get secret -n kube-system azure-credentials -o template='{{index .data "azure_tenant_id"|base64decode}}')
    echo -e "subscriptionId: $subscriptionId\ntenantId: $tenantId\nclientId: $clientId\nclientSecret: $clientSecret" > config/azurecredentials
elif [ "$PLATFORM" == "AWS" ]; then
    accessKeyID=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_access_key_id"|base64decode}}')
    secureKey=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_secret_access_key"|base64decode}}')
    echo -e "[default]\naws_access_key_id=$accessKeyID\naws_secret_access_key=$secureKey" > config/awscredentials
fi