machine:
  certSANs:
    - 127.0.0.1
    - 10.10.0.49
    - k8s.{{ .Data.secretDomain }}
cluster:
  etcd:
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381
    advertisedSubnets:
      - 10.10.0.0/24
---
# Allow scheduling on control-plane nodes
apiVersion: v1alpha1
kind: KubeNodeConfig
taints:
  node-role.kubernetes.io/control-plane:
    $patch: delete
---
apiVersion: v1alpha1
kind: KubeAdmissionControlConfig
name: PodSecurity
$patch: delete
---
apiVersion: v1alpha1
kind: KubeAPIServerConfig
certExtraSANs:
  - 127.0.0.1
  - 10.10.0.49
  - k8s.{{ .Data.secretDomain }}
extraArgs:
  # https://kubernetes.io/docs/tasks/extend-kubernetes/configure-aggregation-layer/
  enable-aggregator-routing: "true"
---
apiVersion: v1alpha1
kind: KubeControllerManagerConfig
extraArgs:
  bind-address: 0.0.0.0
---
apiVersion: v1alpha1
kind: KubeSchedulerConfig
extraArgs:
  bind-address: 0.0.0.0
---
apiVersion: v1alpha1
kind: KubeCoreDNSConfig
enabled: false
---
# Disable built-in CNI and kube-proxy to use Cilium
apiVersion: v1alpha1
kind: KubeFlannelCNIConfig
$patch: delete
---
apiVersion: v1alpha1
kind: KubeProxyConfig
enabled: false
---
apiVersion: v1alpha1
kind: Layer2VIPConfig
name: 10.10.0.49
link: ethSel0
