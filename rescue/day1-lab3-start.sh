#!/bin/bash
# 실습 ③ 시작점 — Jenkins 실행 + ECR 저장소 3개 생성 (작업용 EC2의 shop-app 폴더에서 실행)
# Jenkins 초기 설정(관리자 계정·자격 증명·Multibranch 작업)은 실습 ② 3~6단계를 화면으로 진행한다.
set -e
cd "$(dirname "$0")/.."
docker ps --format '{{.Names}}' | grep -qx jenkins || bash jenkins/run-jenkins.sh
for s in frontend product-api order-api; do
  aws ecr describe-repositories --region ap-northeast-2 --repository-names shop/$s >/dev/null 2>&1 || \
  aws ecr create-repository --region ap-northeast-2 --repository-name shop/$s \
    --tags Key=Course,Value=03 Key=Day,Value=1 --query repository.repositoryUri --output text
done
echo "완료: Jenkins 실행 중, ECR 저장소 3개 준비"
