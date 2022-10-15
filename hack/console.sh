#!/bin/bash

NAMESPACE="clusters"
CLUSTER_NAME=$(oc get hostedclusters -n clusters -o=jsonpath='{.items[0].metadata.name}')

kubedamin_password=$(oc get secret -n "$NAMESPACE-$CLUSTER_NAME" kubeadmin-password --template='{{.data.password | base64decode}}')
echo "guset-password: $kubedamin_password"
echo "https://$(oc --kubeconfig="$SHARED_DIR"/nested_kubeconfig -n openshift-console get routes console -o=jsonpath='{.spec.host}')"