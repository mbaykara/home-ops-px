# Untain the master node

k taint node talos-pvn-2u2 node-role.kubernetes.io/control-plane-

(
  kube_statefulset_status_replicas_ready{job!=""}
    !=
  kube_statefulset_status_replicas{job!=""}
) and (
  changes(kube_statefulset_status_replicas_updated{job!=""}[1m])
    ==
  0
)




kubectl label namespace payment pod-security.kubernetes.io/enforce=privileged