#!/bin/bash

#todo 有待修改

echo -n "namespace? (default:clusters)"
read -r NAMESPACE
if [ ! -n "$NAMESPACE" ]; then
    NAMESPACE="clusters"
fi

gclusters=$(oc get hostedcluster -n "$NAMESPACE" -ojsonpath='{.items[*].metadata.name}')
gclusters_arr=(${gclusters})
for cluster_item in ${gclusters_arr[@]}
do
  echo "begin to destroy cluster ${cluster_item}"
  guest_cluster_region=$(oc get hostedcluster ${cluster_item} -n "$NAMESPACE" -ojsonpath='{.spec.platform.aws.region}')
  hypershift destroy cluster aws \
    --aws-creds config/credentials \
    --namespace "$NAMESPACE" \
    --name ${cluster_item} \
    --region ${guest_cluster_region}
done