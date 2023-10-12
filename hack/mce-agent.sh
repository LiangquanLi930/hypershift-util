#!/bin/bash
set -exuo pipefail

downURL=$(oc get ConsoleCLIDownload hcp-cli-download -o json | jq -r '.spec.links[] | select(.text | test("Linux for x86_64")).href') && curl -k --output /tmp/hcp.tar.gz ${downURL}
pushd /tmp && tar -xvf /tmp/hcp.tar.gz
chmod +x /tmp/hcp
popd

CLUSTER_NAME="test01"
echo "$(date) Creating HyperShift cluster ${CLUSTER_NAME}"
oc create ns "local-cluster-${CLUSTER_NAME}"
BASEDOMAIN=$(oc get dns/cluster -ojsonpath="{.spec.baseDomain}")
PLAYLOADIMAGE=$(oc get clusterversion version -ojsonpath='{.status.desired.image}')
echo "extract secret/pull-secret"
oc extract secret/pull-secret -n openshift-config --to=/tmp --confirm
echo "extract mgmt_iscp.yaml"
oc get imagecontentsourcepolicy -oyaml > /tmp/mgmt_iscp.yaml && yq-go r /tmp/mgmt_iscp.yaml 'items[*].spec.repositoryDigestMirrors' -  | sed  '/---*/d' > /tmp/mgmt_iscp.yaml

/tmp/hcp create cluster agent \
  --name=${CLUSTER_NAME} \
  --pull-secret=/tmp/.dockerconfigjson \
  --namespace local-cluster \
  --agent-namespace="local-cluster-${CLUSTER_NAME}" \
  --base-domain=${BASEDOMAIN} \
  --release-image "$PLAYLOADIMAGE" \
  --image-content-sources /tmp/mgmt_iscp.yaml
