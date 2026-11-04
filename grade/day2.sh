#!/bin/bash
# Day 2 채점 — CloudShell의 shop-app 폴더에서 실행: bash grade/day2.sh
export AWS_REGION=ap-northeast-2; p=0; f=0
ok(){ echo "[PASS] $1"; p=$((p+1)); }
ng(){ echo "[FAIL] $1  → 힌트: $2"; f=$((f+1)); }
cd "$(dirname "$0")/.." || exit 1
ALB=$(aws cloudformation describe-stacks --stack-name shop-ecs --query "Stacks[0].Outputs[?OutputKey=='AlbDns'].OutputValue" --output text 2>/dev/null)
[ -z "$ALB" ] && { echo "[FAIL] shop-ecs 스택 없음 → 실습 ① 1단계"; exit 1; }

a=$(curl -s -m 5 http://$ALB/ | grep -c '<h1>'); b=$(curl -s -m 5 http://$ALB/api/products/health | grep -c product-api); c=$(curl -s -m 5 http://$ALB/api/orders/health | grep -c order-api)
[ "$a$b$c" = 111 ] && ok "ALB 경로 라우팅 (/ → frontend, /api/products → product-api, /api/orders → order-api)" || ng "라우팅 $a$b$c (1이 성공)" "서비스 3개가 RUNNING인지, 대상 그룹 상태가 healthy인지"

n=$(aws ecs describe-services --cluster shop --services frontend product-api order-api \
    --query 'length(services[?runningCount==desiredCount && desiredCount>`0`])' --output text 2>/dev/null)
[ "$n" = 3 ] && ok "ECS 서비스 3개 정상 실행" || ng "정상 서비스 ${n:-0}/3" "bash ecs/create-services.sh"

cb=$(aws ecs describe-services --cluster shop --services frontend product-api order-api \
     --query 'length(services[?deploymentConfiguration.deploymentCircuitBreaker.rollback==`true`])' --output text 2>/dev/null)
[ "$cb" = 3 ] && ok "배포 서킷 브레이커 자동 롤백 설정 3개" || ng "서킷 브레이커 ${cb:-0}/3" "create-services.sh의 deploymentCircuitBreaker"

git fetch -q origin main 2>/dev/null; H=$(git rev-parse origin/main | cut -c1-7)
img=$(aws ecs describe-task-definition --task-definition $(aws ecs describe-services --cluster shop --services frontend --query 'services[0].taskDefinition' --output text) --query 'taskDefinition.containerDefinitions[0].image' --output text 2>/dev/null)
[ "${img##*:}" = "$H" ] && ok "frontend가 main 최신 커밋($H)으로 배포됨" || ng "frontend 태그 ${img##*:}, main $H" "push 후 Jenkins Deploy ECS 단계 확인 (고장 커밋이 main에 남아 있으면 revert)"

rb=$(aws ecs list-service-deployments --cluster shop --service product-api --status ROLLBACK_SUCCESSFUL --query 'length(serviceDeployments)' --output text 2>/dev/null)
[ "${rb:-0}" -ge 1 ] 2>/dev/null && ok "장애 훈련 ②: product-api 자동 롤백 기록 ${rb}건" || ng "롤백 기록 없음" "장애 훈련 ② 고장 이미지 배포"

echo "결과: PASS $p / FAIL $f"
