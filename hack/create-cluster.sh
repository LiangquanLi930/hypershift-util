#!/bin/bash

create_cluster() {
    local option=$1
    echo -n "cluster name?"
    read -r CLUSTER_NAME

    echo "extract secret/pull-secret"
    oc extract secret/pull-secret -n openshift-config --to=config --confirm
    PLAYLOADIMAGE=$(oc get clusterversion version -ojsonpath='{.status.desired.image}')
    echo "playload image: $PLAYLOADIMAGE"

    case "$option" in
        "aws")
            bash "hack/export-credentials.sh" "AWS"
            echo "=========================="
            echo "||  create cluster aws  ||"
            echo "=========================="

            REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')
            echo "region: $REGION"

            oc get imagecontentsourcepolicy -oyaml | yq eval '(.items[0].spec.repositoryDigestMirrors)' - | gsed  '/---*/d' > config/mgmt_iscp.yaml

            PLAYLOADIMAGE=$(oc get clusterversion version -ojsonpath='{.status.desired.image}')
            hypershift create cluster aws \
                --aws-creds config/awscredentials \
                --pull-secret config/.dockerconfigjson \
                --name "$CLUSTER_NAME" \
                --base-domain qe.devcluster.openshift.com \
                --namespace clusters \
                --image-content-sources config/mgmt_iscp.yaml \
                --node-pool-replicas 3 \
                --region "$REGION" \
                --control-plane-availability-policy HighlyAvailable \
                --infra-availability-policy HighlyAvailable \
                --control-plane-operator-image "registry.ci.openshift.org/ocp/4.12:hypershift-operator" \
                --release-image "$PLAYLOADIMAGE" \
                --generate-ssh
            ;;
        "mce-aws")
            bash "hack/export-credentials.sh" "AWS"
            echo "==========================="
            echo "|| create cluster mce-aws ||"
            echo "==========================="
            arch=$(arch)
            if [ "$arch" == "x86_64" ]; then
                downURL=$(oc get ConsoleCLIDownload hypershift-cli-download -o json | jq -r '.spec.links[] | select(.text | test("Mac for x86_64")).href') && curl -k --output /tmp/hypershift.tar.gz ${downURL}
                cd /tmp && tar -xvf /tmp/hypershift.tar.gz
                chmod +x /tmp/hypershift
                cd -
            fi
            if [ "$arch" == "arm64" ]; then
                downURL=$(oc get ConsoleCLIDownload hypershift-cli-download -o json | jq -r '.spec.links[] | select(.text | test("Mac for ARM 64")).href') && curl -k --output /tmp/hypershift.tar.gz ${downURL}
                cd /tmp && tar -xvf /tmp/hypershift.tar.gz
                chmod +x /tmp/hypershift
                cd -
            fi

            echo -n "mce version (default:2.2)"
            read -r MCE_VERSION

            REGION=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')
            echo "region: $REGION"

            oc get imagecontentsourcepolicy -oyaml | yq eval '(.items[0].spec.repositoryDigestMirrors)' - | gsed  '/---*/d' > config/mgmt_iscp.yaml
            /tmp/hypershift create cluster aws \
                --name ${CLUSTER_NAME} \
                --infra-id ${CLUSTER_NAME} \
                --node-pool-replicas 3 \
                --base-domain qe.devcluster.openshift.com \
                --region "$REGION" \
                --pull-secret config/.dockerconfigjson \
                --aws-creds config/awscredentials \
                --image-content-sources config/mgmt_iscp.yaml \
                --namespace local-cluster
            if (( $(echo "$MCE_VERSION < 2.4" | bc -l) )); then
              echo "MCE version is less than 2.4"
              oc annotate hostedclusters -n local-cluster ${CLUSTER_NAME} "cluster.open-cluster-management.io/managedcluster-name=${CLUSTER_NAME}" --overwrite
              oc apply -f - <<EOF
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  annotations:
    import.open-cluster-management.io/hosting-cluster-name: local-cluster
    import.open-cluster-management.io/klusterlet-deploy-mode: Hosted
    open-cluster-management/created-via: other
  labels:
    cloud: auto-detect
    cluster.open-cluster-management.io/clusterset: default
    name: ${CLUSTER_NAME}
    vendor: OpenShift
  name: ${CLUSTER_NAME}
spec:
  hubAcceptsClient: true
  leaseDurationSeconds: 60
EOF
            fi
            ;;
        "kubevirt")
            echo "kubevirt"
            oc get imagecontentsourcepolicy -oyaml | yq eval '(.items[0].spec.repositoryDigestMirrors)' - | gsed  '/---*/d' > config/mgmt_iscp.yaml

            hypershift create cluster kubevirt \
                --pull-secret config/.dockerconfigjson \
                --name "$CLUSTER_NAME" \
                --namespace clusters \
                --node-pool-replicas 1 \
                --memory 16Gi \
                --cores 4 \
                --release-image "$PLAYLOADIMAGE" \
                --generate-ssh
            ;;
        "mce-kubevirt")
            echo "mce-kubevirt"
            ;;
        "agent")
            echo "agent"
            ;;
        "mce-agent")
            echo "============================="
            echo "|| create cluster mce-agent ||"
            echo "============================="
            arch=$(arch)
            if [ "$arch" == "x86_64" ]; then
                downURL=$(oc get ConsoleCLIDownload hypershift-cli-download -o json | jq -r '.spec.links[] | select(.text | test("Mac for x86_64")).href') && curl -k --output /tmp/hypershift.tar.gz ${downURL}
                cd /tmp && tar -xvf /tmp/hypershift.tar.gz
                chmod +x /tmp/hypershift
                cd -
            fi
            if [ "$arch" == "arm64" ]; then
                downURL=$(oc get ConsoleCLIDownload hypershift-cli-download -o json | jq -r '.spec.links[] | select(.text | test("Mac for ARM 64")).href') && curl -k --output /tmp/hypershift.tar.gz ${downURL}
                cd /tmp && tar -xvf /tmp/hypershift.tar.gz
                chmod +x /tmp/hypershift
                cd -
            fi
            oc create ns "clusters-${CLUSTER_NAME}"
            BASEDOMAIN=$(oc get dns/cluster -ojsonpath="{.spec.baseDomain}")
            /tmp/hypershift create cluster agent \
              --name=${CLUSTER_NAME} \
              --pull-secret config/.dockerconfigjson \
              --agent-namespace="clusters-${CLUSTER_NAME}" \
              --base-domain=${BASEDOMAIN} \
              --api-server-address=api.${CLUSTER_NAME}.${BASEDOMAIN}
            ;;
        "azure")
            echo "azure"
            echo "=========================="
            echo "|| create cluster Azure ||"
            echo "=========================="

            bash "hack/export-credentials.sh" "Azure"
            location=$(oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}')
            echo "location: $location"

            hypershift create cluster azure \
                --azure-creds config/azurecredentials \
                --pull-secret config/.dockerconfigjson \
                --name "$CLUSTER_NAME" \
                --base-domain qe.azure.devcluster.openshift.com \
                --namespace clusters \
                --location "$location" \
                --node-pool-replicas 3 \
                --release-image "$PLAYLOADIMAGE" \
                --control-plane-operator-image "registry.ci.openshift.org/ocp/4.12:hypershift-operator" \
                --generate-ssh
            ;;
        *)
            echo "other"
            ;;
    esac
}


menu=("aws" "mce-aws" "kubevirt" "mce-kubevirt" "agent" "mce-agent" "azure")
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