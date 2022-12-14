#!/bin/bash

echo -n "cluster name?"
read -r CLUSTER_NAME
echo -n "infra ID?"
read -r INFRA_ID

REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')

#CLUSTER_NAME is the name of the hosted cluster you intend to create. This is used for creating the Route53 private hosted zones that belong to the cluster.
#AWS_CREDENTIALS_FILE points to an AWS credentials file that has permission to create infrastructure resources for your cluster such as VPCs, subnets, NAT gateways, etc. It should correspond to the AWS account for your guest cluster, where workers will live.
#BASEDOMAIN is the base domain that will be used for your hosted cluster's ingress. It must correspond to an existing Route53 public zone that you have access to create records in.
#INFRA_ID is a unique name that will be used to identify your infrastructure via tags. It is used by the cloud controller manager in Kubernetes and the CAPI manager to identify infrastructure for your cluster. Typically this is the name of your cluster (CLUSTER_NAME) with a random suffix appended to it.
#REGION is the region where you want to create the infrastructure for your cluster.
#OUTPUT_INFRA_FILE is the file where IDs of the infrastructure that has been created will be stored in JSON format. This file can then be used as input to the hypershift create cluster aws command to populate the appropriate fields in the HostedCluster and NodePool resources.
echo "=========================="
echo "||   create infra aws   ||"
echo "=========================="
hypershift create infra aws --name "$CLUSTER_NAME" \
    --aws-creds config/credentials \
    --base-domain qe.devcluster.openshift.com \
    --infra-id "$INFRA_ID" \
    --region "$REGION" \
    --output-file config/"$CLUSTER_NAME"-infra.json

cat config/"$CLUSTER_NAME"-infra.json

#INFRA_ID should be the same id that was specified in the create infra aws command. It is used to identify the IAM resources associated with the hosted cluster.
#AWS_CREDENTIALS_FILE points to an AWS credentials file that has permission to create IAM resources such as roles. It does not have to be the same credentials specified to create the infrastructure but it does have to correspond to the same AWS account.
#OIDC_BUCKET_NAME is the name of the bucket used to store OIDC documents. This bucket should have been created as a prerequisite for installing Hypershift (See Prerequisites) The name of the bucket is used to construct URLs for the OIDC provider created by this command.
#OIDC_BUCKET_REGION is the region where the OIDC bucket lives.
#REGION is the region where the infrastructure of the cluster will live. This is used to create a worker instance profile for machines that belong to the hosted cluster.
#PUBLIC_ZONE_ID is the ID of the public zone for the guest cluster. It is used in creating the policy for the ingress operator. It can be found in the OUTPUT_INFRA_FILE generated by the create infra aws command.
#PRIVATE_ZONE_ID is the ID of the private zone for the guest cluster. It is used in creating the policy for the ingress operator. It can be found in the OUTPUT_INFRA_FILE generated by the create infra aws command.
#LOCAL_ZONE_ID is the ID of the local zone for the guest cluster (when creating a private cluster). It is used in creating the policy for the control plane operator so it can manage records for the PrivateLink endpoint. It can be found in the OUTPUT_INFRA_FILE generated by the create infra aws command.
#OUTPUT_IAM_FILE is the file where IDs of the IAM resources that have been created will be stored in JSON format. This file can then be used as input to the hypershift create cluster aws command to populate the appropriate fields in the HostedCluster and NodePool resource.
echo ""
echo "=========================="
echo "||    create iam aws    ||"
echo "=========================="
PUBLIC_ZONE_ID=$(jq -r ".publicZoneID" < config/"$CLUSTER_NAME"-infra.json)
PRIVATE_ZONE_ID=$(jq -r ".privateZoneID" < config/"$CLUSTER_NAME"-infra.json)
LOCAL_ZONE_ID=$(jq -r ".localZoneID" < config/"$CLUSTER_NAME"-infra.json)
echo "public-zone-id: $PUBLIC_ZONE_ID"
echo "private-zone-id: $PRIVATE_ZONE_ID"
echo "local-zone-id: $LOCAL_ZONE_ID"

hypershift create iam aws --infra-id "$INFRA_ID" \
    --aws-creds config/credentials \
    --region "$REGION" \
    --public-zone-id "$PUBLIC_ZONE_ID" \
    --private-zone-id "$PRIVATE_ZONE_ID" \
    --local-zone-id "$LOCAL_ZONE_ID" \
    --output-file config/"$CLUSTER_NAME"-iam.json

cat config/"$CLUSTER_NAME"-iam.json

####################################################################
#hypershift create iam aws --infra-id "$INFRA_ID" \
#    --aws-creds config/credentials \
#    --oidc-storage-provider-s3-bucket-name OIDC_BUCKET_NAME \
#    --oidc-storage-provider-s3-region OIDC_BUCKET_REGION \
#    --region "$REGION" \
#    --public-zone-id PUBLIC_ZONE_ID \
#    --private-zone-id PRIVATE_ZONE_ID \
#    --local-zone-id LOCAL_ZONE_ID \
#    --output-file config/"$CLUSTER_NAME"-iam.json
####################################################################

#INFRA_ID should be the same id that was specified in the create infra aws command. It is used to identify the IAM resources associated with the hosted cluster.
#CLUSTER_NAME should be the same name that was specified in the create infra aws command.
#AWS_CREDENTIALS should be the same that was specified in the create infra aws command.
#OUTPUT_INFRA_FILE is the file where the output of the create infra aws command was saved.
#OUTPUT_IAM_FILE is the file where the output of the create iam aws command was saved.
#PULL_SECRET_FILE is a file that contains a valid OpenShift pull secret.
echo ""
echo "=========================="
echo "||  create cluster aws  ||"
echo "=========================="
hypershift create cluster aws \
    --infra-id "$INFRA_ID" \
    --name "$CLUSTER_NAME" \
    --aws-creds config/credentials \
    --infra-json config/"$CLUSTER_NAME"-infra.json \
    --iam-json config/"$CLUSTER_NAME"-iam.json \
    --pull-secret config/pull-secret.json \
    --node-pool-replicas 3 \
    --region "$REGION" \
    --generate-ssh