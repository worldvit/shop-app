#!/bin/bash
# ECS 롤링 배포 — Jenkins(작업용 EC2)에서 실행
# 사용법: bash ecs/deploy.sh <이미지태그> [서비스 ...]   (서비스 생략 시 3개 모두)
#         EXTRA_ENV="KEY=값,KEY2=값" bash ecs/deploy.sh ...   → 컨테이너 환경 변수 지정 (생략 시 비움)
# 1) 현재 태스크 정의를 복사해 이미지 태그만 바꾼 새 리비전 등록
# 2) 서비스를 새 리비전으로 업데이트
# 3) 안정화까지 기다린 뒤, 서킷 브레이커가 롤백했는지 확인 (롤백이면 실패 처리)
set -euo pipefail
export AWS_REGION=${AWS_REGION:-ap-northeast-2}
TAG=${1:?이미지 태그를 인자로 주세요}; shift
SERVICES=${*:-frontend product-api order-api}
declare -A NEW

for s in $SERVICES; do
  CUR=$(aws ecs describe-services --cluster shop --services $s --query 'services[0].taskDefinition' --output text)
  aws ecs describe-task-definition --task-definition $CUR --query taskDefinition --output json \
  | jq --arg tag "$TAG" --arg env "${EXTRA_ENV:-}" '
      .containerDefinitions[0].image |= sub(":[^:]+$"; ":" + $tag)
      | .containerDefinitions[0].environment = (($env | select(length>0) | split(",") | map(split("=") | {name:.[0], value:.[1]})) // [])
      | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities,
            .registeredAt, .registeredBy, .deregisteredAt)' > /tmp/td-$s.json
  NEW[$s]=$(aws ecs register-task-definition --cli-input-json file:///tmp/td-$s.json \
            --query taskDefinition.taskDefinitionArn --output text)
  aws ecs update-service --cluster shop --service $s --task-definition ${NEW[$s]} \
    --query 'service.serviceName' --output text >/dev/null
  echo "[$s] ${CUR##*/} → ${NEW[$s]##*/} 배포 시작"
done

echo "안정화 대기 중 (보통 2~4분, 롤백이면 더 걸림)"
aws ecs wait services-stable --cluster shop --services $SERVICES

rc=0
for s in $SERVICES; do
  NOW=$(aws ecs describe-services --cluster shop --services $s \
        --query 'services[0].deployments[?status==`PRIMARY`].taskDefinition | [0]' --output text)
  if [ "$NOW" = "${NEW[$s]}" ]; then echo "[$s] 성공: ${NOW##*/}"
  else echo "[$s] 실패: 서킷 브레이커가 ${NOW##*/} 로 롤백함"; rc=1; fi
done
exit $rc
