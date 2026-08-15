# 🏠 home-ops

My home Kubernetes cluster, run the GitOps way. A 3-node [Talos Linux](https://www.talos.dev/) cluster kept in sync by [Flux](https://fluxcd.io/).

This repository is based on [@onedr0p](https://github.com/onedr0p)'s [cluster template](https://github.com/onedr0p/cluster-template).

## Stack

- **OS**: [Talos Linux](https://www.talos.dev/)
- **GitOps**: [Flux CD](https://fluxcd.io/)
- **Secrets**: [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age)
- **Talos config**: [talhelper](https://budimanjojo.github.io/talhelper/)
- **Tooling**: [mise](https://mise.jdx.dev/) for pinned CLI tools, [Task](https://taskfile.dev/) for automation
- **Updates**: [Renovate](https://www.mend.io/renovate) keeps charts, images, and Actions current

## Components

- **Networking**: [Cilium](https://cilium.io/) (CNI), [CoreDNS](https://coredns.io/), [Envoy Gateway](https://gateway.envoyproxy.io/) (Gateway API), [cert-manager](https://cert-manager.io/), [external-dns](https://kubernetes-sigs.github.io/external-dns/), [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/), [k8s-gateway](https://github.com/ori-edge/k8s_gateway) (internal DNS), [spegel](https://github.com/spegel-org/spegel) (image mirroring), [reloader](https://github.com/stakater/Reloader)
- **Storage**: [rook-ceph](https://rook.io/) with a `CephBlockPool`
- **Observability**: [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack), [Grafana operator](https://grafana.github.io/grafana-operator/), [smartctl-exporter](https://github.com/prometheus-community/smartctl_exporter), [blackbox-exporter](https://github.com/prometheus/blackbox_exporter), [prometheus-adapter](https://github.com/kubernetes-sigs/prometheus-adapter), [silence-operator](https://github.com/giantswarm/silence-operator), [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/), [gatus-sidecar](https://github.com/home-operations/charts)
- **Cluster infra**: [metrics-server](https://github.com/kubernetes-sigs/metrics-server), [snapshot-controller](https://github.com/piraeusdatastore/helm-charts), RBAC

## Repository structure

Follows a three-layer pattern:

```
.
├── bootstrap/            # One-shot cluster bring-up (helmfile: CRDs + core releases)
├── kubernetes/
│   ├── apps/             # Applications, grouped by namespace
│   │   └── <namespace>/
│   │       ├── kustomization.yaml     # Lists each unit's ks.yaml
│   │       └── <unit>/
│   │           ├── ks.yaml            # Flux Kustomization
│   │           └── app/               # HelmRelease + OCIRepository + extras
│   ├── components/       # Reusable Kustomize components (see below)
│   └── flux/             # Flux config (cluster kustomization, HelmRepositories)
├── scripts/              # Bootstrap helper scripts
├── talos/                # Talos machine config (talhelper + SOPS)
├── .taskfiles/           # Task definitions (bootstrap:*, talos:*)
├── Taskfile.yaml         # Task entrypoint
└── .mise.toml            # Pinned CLI toolchain
```

A _unit_ is one Flux Kustomization. Most hold a single app under `app/` (e.g. `apps/network/envoy-gateway/`), but a unit can group several related apps in named sibling directories instead (e.g. `apps/network/external/` covers `external-dns` and `cloudflared`).

`kubernetes/components/` holds three reusable components, referenced from app kustomizations:

- `common/` — namespace plus the SOPS-encrypted cluster secrets and age key
- `alerts/` — Alertmanager provider and alert rules
- `repos/app-template` — shared `OCIRepository` for the app-template chart

## Prerequisites

- [mise](https://mise.jdx.dev/) to install the pinned CLI tools (`task`, `kubectl`, `flux`, `talosctl`, `talhelper`, `sops`, `age`, …):

    ```sh
    mise trust
    mise install
    ```

- An `age.key` referenced by `.sops.yaml` for decrypting secrets, and a `kubeconfig` for cluster access. Both are git-ignored, and both must sit **at the repository root** — `.mise.toml` and `Taskfile.yaml` point `SOPS_AGE_KEY_FILE` and `KUBECONFIG` there, and tasks fail their preconditions if the files are anywhere else.

## Usage

Bootstrap (initial cluster bring-up):

```sh
task bootstrap:talos   # generate secrets, apply Talos config, bootstrap etcd, write kubeconfig
task bootstrap:apps    # namespaces + SOPS secrets + CRDs, then Cilium, CoreDNS, spegel,
                       # cert-manager and Flux; Flux takes over from there
```

Day-to-day:

```sh
task reconcile                          # force Flux to sync with the repo
task talos:generate-config              # (re)generate Talos machine config
task talos:apply-node IP=<node-ip>      # apply Talos config to a node
task talos:upgrade-node IP=<node-ip>    # upgrade Talos on a node
task talos:upgrade-k8s                  # upgrade the Kubernetes version
```

Task definitions live in [.taskfiles/](.taskfiles); run `task` with no arguments to list them.

> [!WARNING]
> `task talos:reset` destroys the cluster and returns every node to maintenance mode, wiping the `STATE` and `EPHEMERAL` partitions. It prompts before running.

## Secrets

Secrets are encrypted with [SOPS](https://github.com/getsops/sops) and committed to the repository as `*.sops.yaml` files. The age private key is the git-ignored `age.key` at the repository root, referenced via the `SOPS_AGE_KEY_FILE` environment variable.

## Dependency updates

[Renovate](https://www.mend.io/renovate) scans Helm charts, container images, and GitHub Actions and opens PRs for updates — configuration lives in [.renovaterc.json5](.renovaterc.json5).
