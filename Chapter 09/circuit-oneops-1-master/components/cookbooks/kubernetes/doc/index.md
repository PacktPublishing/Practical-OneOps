# Kubernetes

tested w/ defaults:
centos 7.2, docker 1.11.2, etcd 2.3.5, k8s 1.2.4, flannel 0.5.3


for installing without internet access:
 * use mirror cloud service with "kubernetes" key mapped to same structure as https://github.com/GoogleCloudPlatform
 * update docker_engine insecure registries
 * update kubernetes-node kubelet pod-infra-container-image
 