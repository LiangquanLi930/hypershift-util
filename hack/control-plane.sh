#!/bin/bash

CLUSTER_NS=$(oc get hostedcluster -A -ojsonpath='{.items[0].metadata.namespace}')
CLUSTER_NAME=$(oc get hostedcluster -n $CLUSTER_NS -ojsonpath='{.items[0].metadata.name}')

oc get pod -n "$CLUSTER_NS-$CLUSTER_NAME"