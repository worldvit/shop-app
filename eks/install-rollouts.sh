#!/bin/bash
# Argo Rollouts 컨트롤러 + kubectl 플러그인 설치 — 작업용 EC2(Session Manager)에서 실행
set -euo pipefail
ROLLOUTS_VERSION=${ROLLOUTS_VERSION:-v1.10.1}
URL=https://github.com/argoproj/argo-rollouts/releases/download/$ROLLOUTS_VERSION
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -n argo-rollouts --server-side --force-conflicts -f $URL/install.yaml >/dev/null
echo "Argo Rollouts $ROLLOUTS_VERSION 설치 중"
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=300s
# kubectl argo rollouts ... 명령을 쓰게 해 주는 플러그인
curl -fsSL -o /tmp/kubectl-argo-rollouts $URL/kubectl-argo-rollouts-linux-amd64
sudo install -m 0755 /tmp/kubectl-argo-rollouts /usr/local/bin/kubectl-argo-rollouts
kubectl argo rollouts version | head -1
