#!/bin/bash
# EKS 클러스터 생성 — CloudShell에서 실행 (15~20분)
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v eksctl >/dev/null; then
  echo "eksctl 설치"
  curl -sSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin/
fi
eksctl version
# 작업용 EC2 역할로 만들면 '만든 사람' 권한과 액세스 항목이 겹쳐 실패하므로 CloudShell(IAM 사용자)에서만 실행
if aws sts get-caller-identity --query Arn --output text | grep -q cicd-workstation-role; then
  echo "이 스크립트는 CloudShell에서 실행하세요 (작업용 EC2에서는 실행하지 않음)"; exit 1
fi
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
sed "s/ACCOUNT_ID/$ACCOUNT/" eks/cluster.yaml > /tmp/cluster.yaml
eksctl create cluster -f /tmp/cluster.yaml
