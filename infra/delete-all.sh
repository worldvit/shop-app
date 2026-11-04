#!/bin/bash
# 과정 전체 삭제 — CloudShell에서 실행 (약 15분). GitHub 저장소는 남는다.
# 작업용 EC2 스택·ECR 저장소를 먼저 지우고, 가장 오래 걸리는 EKS 클러스터 삭제를 기다린다.
set -u
export AWS_REGION=ap-northeast-2
cd "$(dirname "$0")/.."
aws cloudformation delete-stack --stack-name cicd-workstation && echo "[요청] 작업용 EC2 스택 삭제"
aws cloudformation delete-stack --stack-name shop-ecs 2>/dev/null
for s in frontend product-api order-api; do
  aws ecr delete-repository --repository-name shop/$s --force >/dev/null 2>&1 && echo "[삭제] ECR shop/$s"
done
for f in shop-frontend shop-product-api shop-order-api; do
  for a in $(aws ecs list-task-definitions --family-prefix $f --query taskDefinitionArns --output text); do
    aws ecs deregister-task-definition --task-definition $a >/dev/null
    aws ecs delete-task-definitions --task-definitions $a >/dev/null 2>&1
  done
done
echo "[정리] ECS 태스크 정의"
if aws eks describe-cluster --name shop-eks >/dev/null 2>&1; then
  echo "EKS 클러스터 삭제 중 (10~15분, 이 창은 닫지 않는다)"
  bash eks/delete-cluster.sh 2>&1 | grep -E 'deleted|✖|error' | tail -3
fi
aws cloudformation wait stack-delete-complete --stack-name cicd-workstation && echo "[OK] 작업용 EC2 스택 삭제 완료"
bash grade/cleanup-day4.sh
