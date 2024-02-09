#!/bin/bash

CLUSTER_NS=$(oc get hostedcluster -A -ojsonpath='{.items[0].metadata.namespace}')
CLUSTER_NAME=$(oc get hostedcluster -n $CLUSTER_NS -ojsonpath='{.items[0].metadata.name}')

HOSTED_CONTROL_PLANE_NAMESPACE="$CLUSTER_NS-$CLUSTER_NAME"
oc -n ${HOSTED_CONTROL_PLANE_NAMESPACE} get agent -o jsonpath='{range .items[*]}BMH: {@.metadata.labels.agent-install\.openshift\.io/bmh} Agent: {@.metadata.name} State: {@.status.debugInfo.state}{"\n"}{end}'
