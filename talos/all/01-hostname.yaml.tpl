# Pin the hostname; topf otherwise defaults to auto: stable, which would let
# Talos derive it rather than keeping the configured node name.
apiVersion: v1alpha1
kind: HostnameConfig
auto: "off"
hostname: "{{ .Node.Host }}"
