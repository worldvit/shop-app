#!/bin/bash
# EKS 클러스터 삭제 — CloudShell에서 실행 (10~15분). ECR 이미지와 GitHub 저장소는 남는다.
set -u
command -v eksctl >/dev/null || { curl -sSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp && sudo mv /tmp/eksctl /usr/local/bin/; }
eksctl delete cluster --name shop-eks --region ap-northeast-2 --wait
