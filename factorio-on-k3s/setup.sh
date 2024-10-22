#!/bin/bash

# Install sudo
# su -
# apt install -y sudo
# adduser <user> sudo
# systemctl reboot

HOST="" # FQDN used to reach host
RCON_PASSWORD=$(openssl rand -base64 64)

# Install utilities
sudo apt install -y curl vim

# Install K3s (https://docs.k3s.io/quick-start#install-script)
curl -sfL https://get.k3s.io | sh -s - server --service-node-port-range 27015-34197 # from default 30000-32767
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"

# Install Kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management)
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Install Helm (https://helm.sh/docs/intro/install/#from-apt-debianubuntu)
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Install ArgoCD
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd --values argocd-values.yaml --set global.domain=${HOST}

# Configure ArgoCD permissions
kubectl apply -f argocd-app-controller-clusterrole.yaml
kubectl apply -f argocd-app-controller-binding-clusterrolebinding.yaml

# Create Factorio namespace and base resources
kubectl create namespace factorio
kubectl create -n factorio secret generic factorio-rcon --from-literal=password="${RCON_PASSWORD}"
kubectl apply -f factorio-app.yaml
