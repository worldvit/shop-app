#!/bin/bash
# Day 4 시작점 — 작업용 EC2(Session Manager)의 shop-app 폴더에서 실행
# 먼저 CloudShell에서 NODES=3 bash eks/create-cluster.sh 로 클러스터를 만든 뒤 실행한다.
# 하는 일: kubectl 연결 → Argo CD 설치 → dev 앱 등록 → Argo Rollouts 설치
# 사용법: bash rescue/day4-start.sh 내GitHub아이디
set -euo pipefail
GH=${1:?GitHub 아이디를 인수로 주세요}
cd "$(dirname "$0")/.."
bash eks/install-argocd.sh
M=~/shop-manifests
[ -d $M ] || git clone -q https://github.com/$GH/shop-manifests.git $M
cd $M && git pull -q
# Day 3을 끝내지 못해 dev 이미지가 아직 자리 표시자이면 ECR 최신 태그로 맞춰 커밋한다 (push 때 GitHub 토큰 입력)
if grep -q 'ACCOUNT_ID\|"initial"' overlays/dev/kustomization.yaml; then
  TAG=$(aws ecr describe-images --repository-name shop/frontend --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' --output text)
  bash set-images.sh dev "$TAG" >/dev/null
  sed -i "s/GITHUB_USER/$GH/" argocd/app-*.yaml
  git add -A && git commit -qm "dev: 시작점 설정 ($TAG)" && git push -q
fi
sed "s/GITHUB_USER/$GH/" argocd/app-dev.yaml | kubectl apply -f -
cd - >/dev/null
bash eks/install-rollouts.sh
echo "완료: Argo CD UI에서 shop-dev가 Synced·Healthy가 되면 종합 실습 ②를 시작한다"
