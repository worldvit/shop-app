#!/bin/bash
# Day 1 채점 — 작업용 EC2의 shop-app 폴더에서 실행: bash grade/day1.sh
R=ap-northeast-2; p=0; f=0
ok(){ echo "[PASS] $1"; p=$((p+1)); }
ng(){ echo "[FAIL] $1  → 힌트: $2"; f=$((f+1)); }
cd "$(dirname "$0")/.." || exit 1
SVCS="frontend product-api order-api"

c=0; for x in / /api/products /api/orders; do
  [ "$(curl -s -o /dev/null -w '%{http_code}' localhost:8000$x)" = 200 ] && c=$((c+1)); done
[ $c -eq 3 ] && ok "compose로 3서비스 응답 (/ /api/products /api/orders)" || ng "compose 응답 $c/3" "docker compose up -d --build"

if docker ps --format '{{.Names}}' | grep -qx jenkins && \
   [ "$(curl -s -o /dev/null -w '%{http_code}' localhost:8080/login)" = 200 ]; then
  ok "Jenkins 컨테이너 실행 중"; else ng "Jenkins 미실행" "bash jenkins/run-jenkins.sh"; fi

n=0; for s in $SVCS; do aws ecr describe-repositories --region $R --repository-names shop/$s >/dev/null 2>&1 && n=$((n+1)); done
[ $n -eq 3 ] && ok "ECR 저장소 3개 (shop/*)" || ng "ECR 저장소 $n/3" "실습 ③ 1단계 저장소 만들기"

git fetch -q origin main 2>/dev/null
H=$(git rev-parse origin/main 2>/dev/null | cut -c1-7)
m=0; for s in $SVCS; do
  aws ecr describe-images --region $R --repository-name shop/$s --image-ids imageTag=$H >/dev/null 2>&1 && m=$((m+1)); done
[ $m -eq 3 ] && ok "main 최신 커밋($H) 태그 이미지가 3개 저장소 모두에 있음" \
             || ng "커밋 $H 태그 이미지 $m/3" "push 후 Jenkins 빌드가 초록인지, main이 테스트 실패 상태로 남아 있지 않은지 확인"

echo "결과: PASS $p / FAIL $f"
