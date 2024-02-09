#!/bin/bash

NAMESPACE=$(oc get hostedcluster -A -ojsonpath='{.items[0].metadata.namespace}')
CLUSTER_NAME=$(oc get hostedcluster -n "$NAMESPACE" -ojsonpath='{.items[0].metadata.name}')

kubedamin_password=$(oc get secret -n "$NAMESPACE-$CLUSTER_NAME" kubeadmin-password --template='{{.data.password | base64decode}}')
echo "guset-password: $kubedamin_password"
hypershift create kubeconfig --namespace "$NAMESPACE" > hostedcluster.kubeconfig
echo "https://$(oc --kubeconfig=hostedcluster.kubeconfig -n openshift-console get routes console -o=jsonpath='{.spec.host}')"