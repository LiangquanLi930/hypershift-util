#!/bin/bash

echo -n "bucket name? "
read -r BUCKET_NAME
REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')

echo "set aws credentials"
bash "hack/export-credentials.sh" "AWS"
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