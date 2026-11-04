#!/bin/bash
# Day 4 채점 — 작업용 EC2의 shop-app 폴더에서 실행: bash grade/day4.sh
p=0; f=0
ok(){ echo "[PASS] $1"; p=$((p+1)); }
ng(){ echo "[FAIL] $1  → 힌트: $2"; f=$((f+1)); }
cd "$(dirname "$0")/.." || exit 1
kubectl -n argo-rollouts get deploy argo-rollouts -o jsonpath='{.status.availableReplicas}' 2>/dev/null | grep -q '^[1-9]' \
  && ok "Argo Rollouts 컨트롤러 실행 중" || ng "Rollouts 컨트롤러 없음" "bash eks/install-rollouts.sh"
st=$(kubectl -n shop-dev get rollout order-api -o jsonpath='{.status.phase}' 2>/dev/null)
steps=$(kubectl -n shop-dev get rollout order-api -o jsonpath='{.spec.strategy.canary.steps}' 2>/dev/null)
[ "$st" = "Healthy" ] && [ -n "$steps" ] && ok "dev order-api 카나리 Rollout Healthy" \
  || ng "dev order-api Rollout 상태 ${st:-없음}" "종합 실습 ② · kubectl argo rollouts get rollout order-api -n shop-dev"
kubectl -n shop-dev get rs -l app=order-api -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].env}{"\n"}{end}' 2>/dev/null | grep -q BREAK_ORDERS \
  && ok "장애 훈련 ④: 오류 버전 카나리 기록 있음" || ng "BREAK_ORDERS 카나리 기록 없음" "종합 실습 ③"
ab=$(kubectl -n shop-dev get rollout order-api -o jsonpath='{.status.abort}' 2>/dev/null)
env=$(kubectl -n shop-dev get rollout order-api -o jsonpath='{.spec.template.spec.containers[0].env}' 2>/dev/null)
[ "$ab" != "true" ] && ! echo "$env" | grep -q BREAK_ORDERS && ok "Git 되돌리기로 오류 설정 정리됨" \
  || ng "오류 설정이 남아 있음" "매니페스트 저장소에서 git revert 후 push"
grep -q "input " Jenkinsfile && ok "Jenkinsfile에 prod 승인 단계 있음" || ng "승인 단계 없음" "solutions/day4/Jenkinsfile"
M=~/shop-manifests; git -C $M pull -q 2>/dev/null
pc=$(git -C $M log --author=jenkins --grep='deploy(prod)' -1 --format=%s 2>/dev/null)
pst=$(kubectl -n argocd get application shop-prod -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null)
[ "$pst" = "Synced/Healthy" ] && [ -n "$pc" ] && ok "prod가 승인 후 Jenkins 커밋($pc)으로 배포됨" \
  || ng "prod ${pst:-앱 없음}, Jenkins prod 커밋 ${pc:-없음}" "Jenkins 승인 버튼 → Argo CD shop-prod 확인"
[ -f docs/pipeline-guide.md ] && ! grep -q '(작성)' docs/pipeline-guide.md && ok "파이프라인 설명서 작성됨" \
  || ng "docs/pipeline-guide.md 없음 또는 (작성) 칸 남음" "docs/pipeline-guide-template.md를 복사해 작성"
echo "결과: PASS $p / FAIL $f"
