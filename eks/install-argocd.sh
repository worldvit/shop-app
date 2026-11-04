#!/bin/bash
# Argo CD 설치 + UI 열기 — 작업용 EC2(Session Manager)에서 실행
set -euo pipefail
ARGOCD_VERSION=${ARGOCD_VERSION:-v3.5.7}
aws eks update-kubeconfig --name shop-eks --region ap-northeast-2
kubectl get nodes
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml >/dev/null
echo "Argo CD $ARGOCD_VERSION 설치 중 (1~2분)"
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
bash "$(dirname "$0")/argocd-ui.sh"
