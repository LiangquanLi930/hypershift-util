# hypershift-util
### What is HyperShift
HyperShift is middleware for hosting OpenShift control planes at scale that solves for cost and time to provision, as well as portability cross cloud with strong separation of concerns between management and workloads. Clusters are fully compliant OpenShift Container Platform (OCP) clusters and are compatible with standard OCP and Kubernetes toolchains.
### Project Rationale
The primary objective of this project is to streamline the installation process of HyperShift and provide a set of frequently used debug commands. This aims to facilitate everyday usability. We offer essential operations such as `install-operator`, `install-mce`,`create-cluster`, etc.

### Initialization
To get started, follow these steps:

1. Install Go 1.20.
2. Clone the repository: git clone git@github.com:LiangquanLi930/hypershift-util.git && cd hypershift-util && make init.
3. Set up environment variables for both Hypershift and HCP (Hypershift Control Plane):
Hypershift executable: ./hypershift/bin/hypershift
HCP executable: ./hypershift/bin/hcp

Make sure to perform these tasks to properly initialize the environment for your project.
### How to Use
+ create aws bucket
    ```shell
    ➜  make create-aws-bucket
    bucket name? liangli0828-2
    set aws credentials
    AWS export credentials
    {
        "Location": "http://liangli0828-2.s3.amazonaws.com/"
    }
    ```
+ Install HyperShift Operator
    ```shell
    ➜  my git:(main) ✗ make install-operator              
    platform: AWS
    bucket name? liangli0828-2
    created PriorityClass /hypershift-control-plane
    created PriorityClass /hypershift-etcd
    created PriorityClass /hypershift-api-critical
    created PriorityClass /hypershift-operator
    applied Namespace /hypershift
    ...
    Waiting for operator rollout...
    Waiting for deployment "operator" rollout to finish: 0 of 2 updated replicas are available...
    Waiting for deployment "operator" rollout to finish: 0 of 2 updated replicas are available...
    ...
    Deployment "operator" successfully rolled out
    Endpoints available
    ```
+ Create AWS HostedCluster
    ```shell
    make create-cluster  
    > aws
      mce-aws
      kubevirt
      mce-kubevirt
      azure
    cluster name?liangli0820-2
    ...
    ```
+ Delete AWS HostedCluster
    ```shell
    ➜  make destroy-cluster
    namespace? (default:clusters)
    begin to destroy cluster liangli0820-2
    ```
### List of Supported Platforms
- [x] AWS
- [x] MCE-AWS
- [x] Azure
- [ ] KubeVirt
- [ ] MCE-KubeVirt