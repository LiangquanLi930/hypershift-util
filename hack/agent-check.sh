#!/bin/bash

create_cluster() {
    local option=$1
    HOSTED_CLUSTER_NS=$(oc get hostedcluster -A -ojsonpath='{.items[0].metadata.namespace}')
    HOSTED_CLUSTER_NAME=$(oc get hostedclusters -n "$HOSTED_CLUSTER_NS" -ojsonpath="{.items[0].metadata.name}")
    HOSTED_CONTROL_PLANE_NAMESPACE=${HOSTED_CLUSTER_NS}"-"${HOSTED_CLUSTER_NAME}
    # sd
    case "$option" in
        "ignition server")
            oc get pod -n "$HOSTED_CONTROL_PLANE_NAMESPACE" | grep -v "proxy" | grep "ignition" | awk '{print $1}' | xargs -I {} oc logs -n "$HOSTED_CONTROL_PLANE_NAMESPACE" {} | grep -v -i "info"
            ;;
        "capi provider")
            oc get pod -n "$HOSTED_CONTROL_PLANE_NAMESPACE" | grep "capi-provider" | awk '{print $1}' | xargs -I {} oc logs -n "$HOSTED_CONTROL_PLANE_NAMESPACE" {} | grep -v "level=info" | grep -v "INFO"
            ;;
        "control-plane-operator")
            oc get pod -n "$HOSTED_CONTROL_PLANE_NAMESPACE" | grep "control-plane-operator" | awk '{print $1}' | xargs -I {} oc logs -n "$HOSTED_CONTROL_PLANE_NAMESPACE" {} | grep -v '"level":"info"'
            ;;
        "assisted-image-service")
            oc logs -n multicluster-engine assisted-image-service-0
            ;;
        "assisted-service")
            oc get pod -n multicluster-engine | grep "assisted-service" | awk '{print $1}' | xargs -I {} oc logs -n multicluster-engine {} | grep -v "level=info"
            ;;
        *)
            echo "other"
            ;;
    esac
}

menu=("ignition server" "capi provider" "control-plane-operator" "assisted-image-service" "assisted-service")
selected=0

while true; do
    tput el

    for i in "${!menu[@]}"; do
        if [ $i -eq $selected ]; then
            echo -e "\e[32m> ${menu[$i]}\e[0m"
        else
            echo "  ${menu[$i]}"
        fi
    done

    read -rsn1 input
    case $input in
        "A")
            selected=$(( (selected - 1 + ${#menu[@]}) % ${#menu[@]} ))
            ;;
        "B")
            selected=$(( (selected + 1) % ${#menu[@]} ))
            ;;
        "")
            create_cluster "${menu[$selected]}"
            break
            ;;
    esac

    tput cuu "${#menu[@]}"
done