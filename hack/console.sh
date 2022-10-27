#!/bin/bash

NAMESPACE="clusters"
CLUSTER_NAME=$(oc get hostedclusters -n clusters -o=jsonpath='{.items[0].metadata.name}')

kubedamin_password=$(oc get secret -n "$NAMESPACE-$CLUSTER_NAME" kubeadmin-password --template='{{.data.password | base64decode}}')
echo "guset-password: $kubedamin_password"
hypershift create kubeconfig > hostedcluster.kubeconfig
echo "https://$(oc --kubeconfig=hostedcluster.kubeconfig -n openshift-console get routes console -o=jsonpath='{.spec.host}')"