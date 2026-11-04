#!/bin/bash
# Day 2 정리 — CloudShell에서 실행. ECS 서비스 3개 삭제 → shop-ecs 스택(ALB·대상 그룹·클러스터) 삭제
# ECR 저장소와 이미지는 Day 3에서 쓰므로 남긴다.
set -u
export AWS_REGION=ap-northeast-2
for s in frontend product-api order-api; do
  aws ecs delete-service --cluster shop --service $s --force --query 'service.status' --output text 2>/dev/null \
    && echo "[$s] 삭제 요청" || echo "[$s] 서비스 없음"
done
aws ecs wait services-inactive --cluster shop --services frontend product-api order-api 2>/dev/null
aws cloudwatch delete-alarms --alarm-names shop-product-api-5xx 2>/dev/null   # 심화 2에서 만든 알람
echo "서비스 삭제 완료 → 스택 삭제 (3~5분)"
aws cloudformation delete-stack --stack-name shop-ecs
aws cloudformation wait stack-delete-complete --stack-name shop-ecs && echo "[OK] shop-ecs 스택 삭제 완료"
