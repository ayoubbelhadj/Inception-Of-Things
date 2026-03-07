# Inception-of-Things (IoT)

A system administration project introducing Kubernetes through K3s and K3d, using Vagrant for VM provisioning and Argo CD for GitOps continuous deployment.

---

## Structure

```
.
├── p1/          # K3s with Vagrant (server + worker nodes)
├── p2/          # K3s with 3 web applications and Ingress
├── p3/          # K3d cluster with Argo CD (GitOps)
└── bonus/       # K3d + GitLab (self-hosted) + Argo CD (GitOps)
```

---

## Part 1 — K3s and Vagrant

Two virtual machines provisioned with Vagrant running Alpine Linux:

| Machine | Hostname | IP | Role |
|---|---|---|---|
| Server | `abelhadjS` | `192.168.56.110` | K3s controller |
| Worker | `abelhadjSW` | `192.168.56.111` | K3s agent |

**Usage:**

```bash
cd p1
vagrant up
```

SSH into machines:

```bash
vagrant ssh abelhadjS
vagrant ssh abelhadjSW
```

Check cluster status (from server):

```bash
kubectl get nodes -o wide
```

---

## Part 2 — K3s and Three Applications

A single VM running K3s with 3 web applications routed via Ingress based on the `HOST` header.

| Host | App | Replicas |
|---|---|---|
| `app1.com` | app1 | 1 |
| `app2.com` | app2 | 3 |
| *(default)* | app3 | 1 |

**Usage:**

```bash
cd p2
vagrant up
```

Test routing (from the VM):

```bash
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl http://192.168.56.110   # defaults to app3
```

---

## Part 3 — K3d and Argo CD

A K3d cluster running locally with Argo CD managing continuous deployment from a GitHub repository.

**Namespaces:**
- `argocd` — Argo CD
- `dev` — application deployed via GitOps

**GitHub repository:** [IoT-abelhadj](https://github.com/ayoubbelhadj/IoT-abelhadj)

### Setup

**1. Install required tools (Docker, kubectl, K3d):**

```bash
sudo ./p3/scripts/install-tools.sh
```

**2. Create the K3d cluster and install Argo CD:**

```bash
sudo ./p3/scripts/setup-cluster.sh
```

This will print the Argo CD admin password at the end.

**3. Deploy the application:**

```bash
cd p3/scripts
sudo ./deploy-app.sh
```

**4. Access Argo CD UI:**

```bash
sudo kubectl port-forward svc/argocd-server -n argocd 8081:443
# Visit https://localhost:8081  (admin / <password from step 2>)
```

**5. Access the deployed application:**

```bash
sudo kubectl port-forward -n dev svc/playground-service 8888:8888
curl http://localhost:8888
```

### Updating the app version

Edit the deployment in the GitHub repo (`dev/deployment.yaml`), change the image tag (`v1` → `v2`), then commit and push. Argo CD will automatically sync and redeploy.

**Cleanup:**

```bash
sudo ./p3/scripts/cleanup.sh
```

---

## Bonus — GitLab + Argo CD (Self-hosted GitOps)

Same setup as Part 3, but replaces GitHub with a self-hosted GitLab running inside the cluster. The only key difference is `bonus/confs/application.yaml` points to the internal GitLab URL instead of GitHub:

```
http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/IoT-abelhadj.git
```

### Setup

**1. Follow the Part 3 setup** (cluster + Argo CD):

See [Part 3 setup](#part-3--k3d-and-argo-cd) above.

**2. Install and configure GitLab:**

```bash
cd bonus/scripts
./install-gitlab.sh    # installs GitLab via Helm (~10 min)
./setup-gitlab.sh      # prints credentials and push instructions
```

**3. Deploy using the bonus application manifest** (points to GitLab instead of GitHub):

```bash
kubectl apply -f bonus/confs/application.yaml
```

### Cleanup

```bash
cd bonus/scripts
./cleanup-gitlab.sh       # remove GitLab only
./cleanup-cluster.sh      # remove the cluster
```

---

## Requirements

- [Vagrant](https://www.vagrantup.com/) + [VirtualBox](https://www.virtualbox.org/) (Parts 1 & 2)
- [Docker](https://www.docker.com/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [K3d](https://k3d.io/) (Parts 3 & Bonus)
- [Helm](https://helm.sh/) (Bonus)
