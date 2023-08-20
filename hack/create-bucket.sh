#!/bin/bash

echo -n "bucket name? "
read -r BUCKET_NAME
REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')

echo "set aws credentials"
bash "hack/export-credentials.sh" "AWS"
cp -f "config/awscredentials" "$HOME/.aws/credentials"

aws s3api head-bucket --bucket "$BUCKET_NAME" > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    echo "this bucket already exists"
else
    if [ "$REGION" == "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME" \
            --region us-east-1
        aws s3api delete-public-access-block --bucket "$BUCKET_NAME"
        echo -e "$BUCKET_NAME\t$REGION" >> "config/aws_bucket"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" \
            --create-bucket-configuration LocationConstraint="$REGION" \
            --region "$REGION"
        aws s3api delete-public-access-block --bucket "$BUCKET_NAME"
        echo -e "$BUCKET_NAME\t$REGION" >> "config/aws_bucket"
    fi
    aws s3api delete-public-access-block --bucket "$BUCKET_NAME"
    export BUCKET_NAME=$BUCKET_NAME
    echo '{
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
            }
        ]
    }' | envsubst > config/policy.json
    aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://config/policy.json
fi