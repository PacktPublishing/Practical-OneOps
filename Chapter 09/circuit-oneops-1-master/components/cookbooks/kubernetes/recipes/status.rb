# Cookbook Name:: kubernetes
# Attributes:: status
#
# Author : OneOps
# Apache License, Version 2.0

if node.workorder.ci.ciName.include?("-master")
  %w(kube-apiserver kube-controller-manager kube-scheduler).each do |service|
    service service do
      action [:status]
    end
  end
else
  %w(kubelet kube-proxy).each do |service|
    service service do
      action [:status]
    end
  end    
end
