# GateKey Helm Chart

A Helm chart for deploying [GateKey](https://github.com/dye-tech/GateKey) - a modern Zero-Trust VPN control plane.

## Docker Images

GateKey images are available on Docker Hub:

- [`dyetech/gatekey-server`](https://hub.docker.com/r/dyetech/gatekey-server) - GateKey server/control plane
- [`dyetech/gatekey-web`](https://hub.docker.com/r/dyetech/gatekey-web) - GateKey web UI

All images include:
- Multi-arch support (linux/amd64, linux/arm64)
- Non-root user (UID 65532)
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

### Install with custom values

```bash
helm install gatekey gatekey/gatekey -n gatekey --create-namespace \
  --set config.server.corsOrigins[0]="https://gatekey.example.com" \
  --set config.auth.oidc.enabled=true
```

## Configuration

See [values.yaml](values.yaml) for the full list of configurable parameters.

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `server.enabled` | Enable GateKey server | `true` |
| `server.replicaCount` | Number of server replicas | `1` |
| `server.image.repository` | Server image repository | `dyetech/gatekey-server` |
| `server.image.tag` | Server image tag | `1.1.3` |
| `web.enabled` | Enable GateKey web UI | `true` |
| `web.replicaCount` | Number of web UI replicas | `2` |
| `postgresql.enabled` | Deploy PostgreSQL | `true` |
| `postgresql.persistence.size` | PostgreSQL storage size | `10Gi` |
| `config.auth.oidc.enabled` | Enable OIDC authentication | `false` |
| `secrets.adminPassword` | Initial admin password (optional) | `""` (auto-generated) |

### Setting Initial Admin Password

By default, GateKey generates a random admin password on first startup and stores it in a Kubernetes secret. You can set a custom password:

```bash
helm install gatekey gatekey/gatekey -n gatekey --create-namespace \
  --set secrets.adminPassword="your-secure-password"
```

To retrieve the auto-generated password:

```bash
kubectl get secret gatekey-admin-password -n gatekey -o jsonpath='{.data.admin-password}' | base64 -d
```

### Using an External Database

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

### Enabling OIDC Authentication

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
