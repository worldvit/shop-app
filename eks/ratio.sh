#!/bin/bash
# 클러스터 안에서 order-api 서비스로 N번 요청해 "상태코드 버전" 비율을 센다
# (kubectl run -i는 붙기 전 출력을 놓칠 수 있어 3초 기다린 뒤 요청)
# 사용법: bash eks/ratio.sh [요청 수] [네임스페이스]   예) bash eks/ratio.sh 100 shop-dev
N=${1:-100}; NS=${2:-shop-dev}
kubectl -n "$NS" run "ratio-$RANDOM" --rm -i --quiet --restart=Never --image=curlimages/curl:8.11.1 -- \
  sh -c "sleep 3; for i in \$(seq $N); do curl -s -o /dev/null -w '%{http_code} %header{x-app-version}\n' http://order-api:5000/api/orders; done" \
  | sort | uniq -c | awk '{printf "  %-4s 버전 %-8s : %3d회\n", $2, $3, $1}'
