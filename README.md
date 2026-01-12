# GateKey Helm Chart

A Helm chart for deploying [GateKey](https://github.com/dye-tech/GateKey) - a modern Zero-Trust VPN control plane.

## Docker Images

GateKey images are available on Docker Hub:

- [`dyetech/gatekey-server`](https://hub.docker.com/r/dyetech/gatekey-server) - Control plane server
- [`dyetech/gatekey-web`](https://hub.docker.com/r/dyetech/gatekey-web) - Web UI
- [`dyetech/gatekey-gateway`](https://hub.docker.com/r/dyetech/gatekey-gateway) - OpenVPN gateway
- [`dyetech/gatekey-hub`](https://hub.docker.com/r/dyetech/gatekey-hub) - OpenVPN mesh hub
- [`dyetech/gatekey-mesh-gateway`](https://hub.docker.com/r/dyetech/gatekey-mesh-gateway) - OpenVPN mesh spoke
- [`dyetech/gatekey-wireguard-gateway`](https://hub.docker.com/r/dyetech/gatekey-wireguard-gateway) - WireGuard gateway
- [`dyetech/gatekey-wireguard-hub`](https://hub.docker.com/r/dyetech/gatekey-wireguard-hub) - WireGuard mesh hub
- [`dyetech/gatekey-wireguard-mesh-gateway`](https://hub.docker.com/r/dyetech/gatekey-wireguard-mesh-gateway) - WireGuard mesh spoke

All images include:
- Multi-arch support (linux/amd64, linux/arm64)
- Non-root user where applicable
- Supply chain attestations (SBOM + Provenance)

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistence)

## Installation

### Add the Helm repository

```bash
helm repo add gatekey https://dye-tech.github.io/gatekey-helm-chart
helm repo update
```

### Install the chart

```bash
helm install gatekey gatekey/gatekey -n gatekey --create-namespace
```

## Deployment Scenarios

This chart supports flexible deployment patterns. You can deploy all components together or separately across different clusters.

### Scenario 1: Full Deployment (All-in-One)

Deploy the complete GateKey stack including server, web UI, database, and VPN gateways in a single cluster.

```bash
helm install gatekey gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=true \
  --set web.enabled=true \
  --set postgresql.enabled=true \
  --set openvpnGateway.enabled=true \
  --set openvpnGateway.token="your-gateway-token"
```

### Scenario 2: Control Plane Only

Deploy just the server, web UI, and database. VPN gateways will be deployed separately.

```bash
helm install gatekey gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=true \
  --set web.enabled=true \
  --set postgresql.enabled=true
```

### Scenario 3: OpenVPN Gateway (Remote Deployment)

Deploy an OpenVPN gateway in a separate cluster that connects back to your central GateKey server.

```bash
# First, get the gateway token from the GateKey admin panel

helm install gatekey-gateway gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=false \
  --set web.enabled=false \
  --set postgresql.enabled=false \
  --set global.serverUrl=https://gatekey.example.com \
  --set openvpnGateway.enabled=true \
  --set openvpnGateway.token="your-gateway-token"
```

### Scenario 4: WireGuard Gateway (Remote Deployment)

Deploy a WireGuard gateway in a separate cluster.

```bash
helm install gatekey-wg-gateway gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=false \
  --set web.enabled=false \
  --set postgresql.enabled=false \
  --set global.serverUrl=https://gatekey.example.com \
  --set wireguardGateway.enabled=true \
  --set wireguardGateway.token="your-gateway-token"
```

### Scenario 5: OpenVPN Mesh Hub

Deploy an OpenVPN mesh hub that spoke gateways connect to for site-to-site networking.

```bash
helm install gatekey-hub gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=false \
  --set web.enabled=false \
  --set postgresql.enabled=false \
  --set global.serverUrl=https://gatekey.example.com \
  --set openvpnHub.enabled=true \
  --set openvpnHub.token="your-hub-token"
```

### Scenario 6: OpenVPN Mesh Spoke

Deploy an OpenVPN spoke that connects to a hub for mesh networking.

```bash
helm install gatekey-spoke gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=false \
  --set web.enabled=false \
  --set postgresql.enabled=false \
  --set global.serverUrl=https://gatekey.example.com \
  --set openvpnSpoke.enabled=true \
  --set openvpnSpoke.token="your-spoke-token" \
  --set openvpnSpoke.hubAddress=hub.example.com \
  --set openvpnSpoke.hubPort=1194
```

### Scenario 7: WireGuard Mesh Hub

Deploy a WireGuard mesh hub.

```bash
helm install gatekey-wg-hub gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=false \
  --set web.enabled=false \
  --set postgresql.enabled=false \
  --set global.serverUrl=https://gatekey.example.com \
  --set wireguardHub.enabled=true \
  --set wireguardHub.token="your-hub-token"
```

### Scenario 8: WireGuard Mesh Spoke

Deploy a WireGuard spoke that connects to a hub.

```bash
helm install gatekey-wg-spoke gatekey/gatekey -n gatekey --create-namespace \
  --set server.enabled=false \
  --set web.enabled=false \
  --set postgresql.enabled=false \
  --set global.serverUrl=https://gatekey.example.com \
  --set wireguardSpoke.enabled=true \
  --set wireguardSpoke.token="your-spoke-token" \
  --set wireguardSpoke.hubAddress=wg-hub.example.com \
  --set wireguardSpoke.hubPort=51820
```

## Token Authentication

VPN components (gateways, hubs, spokes) authenticate with the GateKey server using tokens. Tokens are generated in the GateKey admin panel when you create a gateway or mesh node.

### Setting Token Directly

```bash
--set openvpnGateway.token="gk_abc123..."
```

### Using an Existing Secret

For production deployments, store the token in a Kubernetes secret:

```bash
# Create the secret
kubectl create secret generic gateway-credentials \
  --from-literal=token="gk_abc123..." \
  -n gatekey

# Reference it in the Helm install
helm install gatekey-gateway gatekey/gatekey -n gatekey \
  --set openvpnGateway.enabled=true \
  --set openvpnGateway.existingSecret=gateway-credentials \
  --set openvpnGateway.existingSecretKey=token \
  --set global.serverUrl=https://gatekey.example.com
```

## Configuration Reference

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secrets | `[]` |
| `global.storageClass` | Global storage class | `""` |
| `global.serverUrl` | GateKey server URL for remote VPN components | `""` (uses in-cluster service) |

### Server Component

| Parameter | Description | Default |
|-----------|-------------|---------|
| `server.enabled` | Enable GateKey server | `true` |
| `server.replicaCount` | Number of server replicas | `1` |
| `server.image.repository` | Server image repository | `dyetech/gatekey-server` |
| `server.image.tag` | Server image tag | `1.2.2` |

### Web UI Component

| Parameter | Description | Default |
|-----------|-------------|---------|
| `web.enabled` | Enable GateKey web UI | `true` |
| `web.replicaCount` | Number of web UI replicas | `2` |
| `web.image.repository` | Web image repository | `dyetech/gatekey-web` |
| `web.image.tag` | Web image tag | `1.2.2` |

### OpenVPN Gateway

| Parameter | Description | Default |
|-----------|-------------|---------|
| `openvpnGateway.enabled` | Enable OpenVPN gateway | `false` |
| `openvpnGateway.image.repository` | Gateway image | `dyetech/gatekey-gateway` |
| `openvpnGateway.token` | Authentication token | `""` |
| `openvpnGateway.existingSecret` | Use existing secret for token | `""` |
| `openvpnGateway.existingSecretKey` | Key in existing secret | `gateway-token` |
| `openvpnGateway.service.type` | Service type | `LoadBalancer` |
| `openvpnGateway.service.port` | Service port | `1194` |
| `openvpnGateway.service.protocol` | Protocol (UDP/TCP) | `UDP` |

### OpenVPN Hub

| Parameter | Description | Default |
|-----------|-------------|---------|
| `openvpnHub.enabled` | Enable OpenVPN hub | `false` |
| `openvpnHub.image.repository` | Hub image | `dyetech/gatekey-hub` |
| `openvpnHub.token` | Authentication token | `""` |
| `openvpnHub.existingSecret` | Use existing secret for token | `""` |
| `openvpnHub.service.type` | Service type | `LoadBalancer` |
| `openvpnHub.service.port` | Service port | `1194` |

### OpenVPN Spoke

| Parameter | Description | Default |
|-----------|-------------|---------|
| `openvpnSpoke.enabled` | Enable OpenVPN spoke | `false` |
| `openvpnSpoke.image.repository` | Spoke image | `dyetech/gatekey-mesh-gateway` |
| `openvpnSpoke.token` | Authentication token | `""` |
| `openvpnSpoke.existingSecret` | Use existing secret for token | `""` |
| `openvpnSpoke.hubAddress` | Hub address to connect to | `""` |
| `openvpnSpoke.hubPort` | Hub port | `1194` |

### WireGuard Gateway

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wireguardGateway.enabled` | Enable WireGuard gateway | `false` |
| `wireguardGateway.image.repository` | Gateway image | `dyetech/gatekey-wireguard-gateway` |
| `wireguardGateway.token` | Authentication token | `""` |
| `wireguardGateway.existingSecret` | Use existing secret for token | `""` |
| `wireguardGateway.service.type` | Service type | `LoadBalancer` |
| `wireguardGateway.service.port` | Service port | `51820` |

### WireGuard Hub

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wireguardHub.enabled` | Enable WireGuard hub | `false` |
| `wireguardHub.image.repository` | Hub image | `dyetech/gatekey-wireguard-hub` |
| `wireguardHub.token` | Authentication token | `""` |
| `wireguardHub.existingSecret` | Use existing secret for token | `""` |
| `wireguardHub.service.type` | Service type | `LoadBalancer` |
| `wireguardHub.service.port` | Service port | `51820` |

### WireGuard Spoke

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wireguardSpoke.enabled` | Enable WireGuard spoke | `false` |
| `wireguardSpoke.image.repository` | Spoke image | `dyetech/gatekey-wireguard-mesh-gateway` |
| `wireguardSpoke.token` | Authentication token | `""` |
| `wireguardSpoke.existingSecret` | Use existing secret for token | `""` |
| `wireguardSpoke.hubAddress` | Hub address to connect to | `""` |
| `wireguardSpoke.hubPort` | Hub port | `51820` |

### PostgreSQL

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Deploy PostgreSQL | `true` |
| `postgresql.auth.username` | Database username | `gatekey` |
| `postgresql.auth.database` | Database name | `gatekey` |
| `postgresql.persistence.size` | Storage size | `10Gi` |

### External Database

| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalDatabase.host` | External database host | `""` |
| `externalDatabase.port` | External database port | `5432` |
| `externalDatabase.database` | Database name | `gatekey` |
| `externalDatabase.username` | Database username | `gatekey` |
| `externalDatabase.existingSecret` | Secret containing password | `""` |

## Setting Initial Admin Password

By default, GateKey generates a random admin password on first startup and stores it in a Kubernetes secret.

Set a custom password:

```bash
helm install gatekey gatekey/gatekey -n gatekey --create-namespace \
  --set secrets.adminPassword="your-secure-password"
```

Retrieve the auto-generated password:

```bash
kubectl get secret gatekey-secrets -n gatekey -o jsonpath='{.data.admin-password}' | base64 -d
```

## Using an External Database

```yaml
postgresql:
  enabled: false

externalDatabase:
  host: "your-postgres-host.example.com"
  port: 5432
  database: "gatekey"
  username: "gatekey"
  existingSecret: "my-db-secret"
  existingSecretKey: "password"
```

## Enabling OIDC Authentication

```yaml
config:
  auth:
    oidc:
      enabled: true
      providers:
        - name: "keycloak"
          displayName: "SSO Login"
          issuer: "https://keycloak.example.com/realms/master"
          clientId: "gatekey"
          clientSecret: "your-secret"
          redirectUrl: "https://gatekey.example.com/api/v1/auth/oidc/callback"
          scopes:
            - "openid"
            - "profile"
            - "email"
            - "groups"

secrets:
  oidcClientId: "gatekey"
  oidcClientSecret: "your-secret"
```

## Architecture Overview

```
                    ┌─────────────────────────────────────┐
                    │         Central Cluster             │
                    │  ┌─────────┐  ┌─────────┐          │
                    │  │ Server  │  │   Web   │          │
                    │  └────┬────┘  └─────────┘          │
                    │       │                            │
                    │  ┌────┴────┐                       │
                    │  │PostgreSQL│                      │
                    │  └─────────┘                       │
                    └─────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
           ┌────────▼────────┐ ┌────▼────┐ ┌───────▼───────┐
           │  Edge Cluster A │ │  AWS    │ │ Edge Cluster B│
           │  ┌───────────┐  │ │┌───────┐│ │ ┌───────────┐ │
           │  │  OpenVPN  │  │ ││WireGrd││ │ │   Hub     │ │
           │  │  Gateway  │  │ ││Gateway││ │ └─────┬─────┘ │
           │  └───────────┘  │ │└───────┘│ │       │       │
           └─────────────────┘ └─────────┘ │ ┌─────▼─────┐ │
                                           │ │   Spoke   │ │
                                           │ └───────────┘ │
                                           └───────────────┘
```

## Upgrading

```bash
helm upgrade gatekey gatekey/gatekey -n gatekey
```

## Uninstalling

```bash
helm uninstall gatekey -n gatekey
```

**Note:** This will not delete the PVCs. To delete them:

```bash
kubectl delete pvc -n gatekey -l app.kubernetes.io/name=gatekey
```

## License

Apache 2.0 - See [LICENSE](https://github.com/dye-tech/GateKey/blob/main/LICENSE)
