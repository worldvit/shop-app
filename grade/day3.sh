#!/bin/bash
# Day 3 채점 — 작업용 EC2의 shop-app 폴더에서 실행: bash grade/day3.sh
p=0; f=0
ok(){ echo "[PASS] $1"; p=$((p+1)); }
ng(){ echo "[FAIL] $1  → 힌트: $2"; f=$((f+1)); }
cd "$(dirname "$0")/.." || exit 1
n=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2=="Ready"' | wc -l)
[ "$n" -ge 2 ] && ok "EKS 노드 ${n}개 Ready" || ng "Ready 노드 $n개" "aws eks update-kubeconfig --name shop-eks"
kubectl -n argocd get deploy argocd-server -o jsonpath='{.status.availableReplicas}' 2>/dev/null | grep -q '^[1-9]' \
  && ok "Argo CD 서버 실행 중" || ng "Argo CD 없음" "bash eks/install-argocd.sh"
st=$(kubectl -n argocd get application shop-dev -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null)
[ "$st" = "Synced/Healthy" ] && ok "shop-dev 앱 Synced/Healthy" || ng "shop-dev 상태 ${st:-없음}" "kubectl apply -f argocd/app-dev.yaml (repoURL 확인)"
sh=$(kubectl -n argocd get application shop-dev -o jsonpath='{.spec.syncPolicy.automated.selfHeal}' 2>/dev/null)
[ "$sh" = "true" ] && ok "자동 동기화 + self-heal 설정" || ng "selfHeal 꺼짐" "app-dev.yaml syncPolicy"
git fetch -q origin main 2>/dev/null; H=$(git rev-parse origin/main | cut -c1-7)
img=$(kubectl -n shop-dev get deploy product-api -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "${img##*:}" = "$H" ] && ok "shop-app main 최신 커밋($H)이 EKS에 반영됨" || ng "EKS 태그 ${img##*:}, main $H" "Jenkins Update Manifest 단계와 Argo CD 동기화(최대 3분) 확인"
echo "결과: PASS $p / FAIL $f"
