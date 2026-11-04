#!/bin/bash
# 배포 중 무중단 확인 — 0.2초마다 요청을 보내 상태 코드와 응답 버전을 센다. Ctrl+C로 끝내면 합계 출력
# 사용법: bash ecs/watch.sh http://<ALB 주소>/api/products
URL=${1:?ALB 주소와 경로를 주세요 (예: http://shop-alb-xxx.ap-northeast-2.elb.amazonaws.com/api/products)}
ok=0; ng=0; declare -A ver
summary(){ echo; echo "== 합계: 성공 $ok / 실패 $ng"; for v in "${!ver[@]}"; do echo "   버전 $v : ${ver[$v]}회"; done; exit 0; }
trap summary INT
while true; do
  r=$(curl -s -m 2 -o /dev/null -w '%{http_code} %header{x-app-version}' "$URL")
  code=${r%% *}; v=${r#* }
  if [ "$code" = 200 ]; then ok=$((ok+1)); ver[$v]=$(( ${ver[$v]:-0}+1 ))
  else ng=$((ng+1)); echo "$(date +%T) 실패 응답: $code"; fi
  [ $(( (ok+ng) % 25 )) -eq 0 ] && echo "$(date +%T) 성공 $ok 실패 $ng 최근 버전 $v"
  sleep 0.2
done
