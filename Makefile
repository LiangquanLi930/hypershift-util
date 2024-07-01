check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: init
init: ## init, Init configuration, need to export an env variable for hypershift client binary,
	@git clone git@github.com:openshift/hypershift.git && mkdir -p config && echo "hypershift client binary path: `pwd`./hypershift/bin/hypershift, `pwd`./hypershift/bin/hcp"

.PHONY: update-cli
update-cli: ## update hypershift cli
	@cd hypershift && git checkout . && git pull && make hypershift && make product-cli

#hypershift install
.PHONY: install-operator
install-operator: ## install HyperShift operator
	@bash hack/install-operator.sh

.PHONY: uninstall-operator
uninstall-operator: ## uninstall HyperShift operator. check: oc get all -n hypershift
	@hypershift install render --format=yaml | oc delete -f -

.PHONY: get-node-internal-ip
get-node-internal-ip: ## get node InternalIP
	@oc get node -o jsonpath='{range .items[*]}Node: {@.metadata.name}  InternalIP: {@.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'

.PHONY: get-hypershift-supported-versions
get-hypershift-supported-versions: ## get HyperShift supported versions
	@oc get cm -n hypershift supported-versions -ojsonpath='{.data}' | jq

.PHONY: get-hypershift-version
get-hypershift-version: ## get HyperShift version
	@oc logs -n hypershift -lapp=operator --tail=-1 -c operator | head -1 | jq

.PHONY: get-mce-version
get-mce-version: ## get multiclusterengines version
	@oc get multiclusterengines multiclusterengine-sample  -ojsonpath="{.status.currentVersion}"

.PHONY: get-region
get-region: ## get cluster region
	@oc get node -ojsonpath='{.items[].metadata.labels.topology\.kubernetes\.io/region}'

.PHONY: get-platform
get-platform: ## get cluster platform
	@oc get infrastructure cluster -o=jsonpath='{.status.platformStatus.type}'

.PHONY: get-architecture
get-architecture: ## get cluster architecture
	@oc get node -ojsonpath='{.items[*].status.nodeInfo.architecture}'

.PHONY: get-baseDomain
get-baseDomain: ## get cluster baseDomain
	@oc get dns -ojsonpath='{.items[].spec.baseDomain}'

.PHONY: get-hostedcluster-cp
get-hostedcluster-cp: ## get HostedCluster Control Plane
	@bash hack/control-plane.sh

.PHONY: get-hostedcluster-cp-ns
get-hostedcluster-cp-ns: ## get HostedCluster Control Plane NameSpace
	@bash hack/control-plane-ns.sh

.PHONY: get-agent-state
get-agent-state: ## get agent state
	@bash hack/agent-state.sh

.PHONY: check-agent-logs
check-agent-logs: ## check agent logs
	@bash hack/agent-check.sh

.PHONY: export-credentials
export-credentials: ## export credentials (support: AWS,Azure)
	@bash hack/export-credentials.sh

.PHONY: export-pull-secret
export-pull-secret: ## export pull-secret
	@oc extract secret/pull-secret -n openshift-config --to=config --confirm

# need aws cli https://docs.aws.amazon.com/zh_cn/cli/v1/userguide/install-macos.html
.PHONY: create-aws-bucket
create-aws-bucket: ## create aws An S3 bucket with public access to host OIDC discovery documents for your clusters.
	@bash hack/create-bucket.sh

.PHONY: create-cluster
create-cluster: ## create hosted cluster (AWS,Azure)
	@bash hack/create-cluster.sh

.PHONY: create-cluster-manual
create-cluster-manual: ## create hosted cluster (AWS) manual
	@bash hack/create-cluster-manual.sh

.PHONY: destroy-cluster
destroy-cluster: ## destroy hosted cluster (AWS,Azure,kubevirt)
	@bash hack/destroy-cluster.sh

.PHONY: create-kubeconfig
create-kubeconfig: ## create hosted cluster kubeconfig > hostedcluster.kubeconfig
	@hypershift create kubeconfig --namespace "$(oc get hostedcluster -A -ojsonpath='{.items[0].metadata.namespace}')" > hostedcluster.kubeconfig

.PHONY: guest-console-info
guest-console-info: ## get hosted cluster web console info
	@bash hack/console.sh

.PHONY: guest-create-user
guest-create-user: ## create user for guest cluster
	@bash hack/create-user.sh

.PHONY: install-mce
install-mce: ## install mce operator
	@bash hack/install-mce.sh