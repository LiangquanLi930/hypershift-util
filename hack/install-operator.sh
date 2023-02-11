#!/bin/bash

platform=$(oc get infrastructure cluster -o=jsonpath='{.status.platformStatus.type}')
echo "platform: $platform"
kubevirt=$(oc get customresourcedefinitions | grep hyperconvergeds | wc -l)
if [ "$kubevirt" -gt 0 ]; then
    echo "kubevirt"
    hypershift install \
        --hypershift-image "quay.io/hypershift/hypershift-operator:latest"
elif [ "$platform" == 'Azure' ]; then
    hypershift install \
        --hypershift-image "quay.io/hypershift/hypershift-operator:latest"
elif [ "$platform" == "AWS" ]; then
    echo -n "bucket name? "
    read -r BUCKET_NAME
    REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')

    accessKeyID=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_access_key_id"|base64decode}}')
    secureKey=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_secret_access_key"|base64decode}}')
    echo -e "[default]\naws_access_key_id=$accessKeyID\naws_secret_access_key=$secureKey" > "config/awscredentials"

    hypershift install \
    		--oidc-storage-provider-s3-bucket-name "$BUCKET_NAME" \
    		--oidc-storage-provider-s3-credentials "config/awscredentials" \
    		--oidc-storage-provider-s3-region "$REGION" \
    		--hypershift-image "quay.io/hypershift/hypershift-operator:latest"
fi