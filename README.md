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
