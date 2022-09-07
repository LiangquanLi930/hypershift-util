#!/bin/bash

echo -n "bucket name? "
read -r BUCKET_NAME
echo -n "region name? "
read -r REGION

echo "set aws credentials"
accessKeyID=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_access_key_id"|base64decode}}')
secureKey=$(oc get secret -n kube-system aws-creds -o template='{{index .data "aws_secret_access_key"|base64decode}}')
echo -e "[default]\naws_access_key_id=$accessKeyID\naws_secret_access_key=$secureKey" > "config/awscredentials"
cp -f "config/awscredentials" "$HOME/.aws/credentials"

aws s3api head-bucket --bucket "$BUCKET_NAME"
if [ $? -eq 0 ] ; then
    echo "this bucket already exists"
else
    aws s3api create-bucket --acl public-read --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" \
        --region "$REGION"
    echo -e "$BUCKET_NAME\t$REGION" >> "config/aws_bucket"
fi