# Node networking as Talos 1.13+ typed network documents. Mirrors what
# talhelper generated from talconfig.yaml networkInterfaces.
apiVersion: v1alpha1
kind: LinkAliasConfig
name: ethSel0
selector:
  match: glob("{{ .Node.Data.macAddr }}", mac(link.hardware_addr))
---
apiVersion: v1alpha1
kind: LinkConfig
name: ethSel0
mtu: {{ .Node.Data.mtu }}
addresses:
  - address: {{ .Node.IP }}/24
routes:
  - gateway: 10.10.0.1
