#!/bin/bash
# ECS 서비스 3개 최초 생성 — CloudShell에서 shop-app 폴더 기준으로 실행
# 사용법: bash ecs/create-services.sh [이미지태그]   (생략하면 서비스별 ECR 최신 태그)
set -euo pipefail
export AWS_REGION=ap-northeast-2
cd "$(dirname "$0")/.."

out(){ aws cloudformation describe-stacks --stack-name shop-ecs \
  --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text; }
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
SUBNETS=$(out Subnets); TASK_SG=$(out TaskSG)

declare -A TG=( [frontend]=$(out FrontendTG) [product-api]=$(out ProductTG) [order-api]=$(out OrderBlueTG) )
declare -A PORT=( [frontend]=80 [product-api]=5000 [order-api]=5000 )

for s in frontend product-api order-api; do
  TAG=${1:-$(aws ecr describe-images --repository-name shop/$s \
        --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' --output text)}
  echo "== $s : 이미지 태그 $TAG"

  # 1) 태스크 정의 등록 (자리 표시자 __ACCOUNT__, __TAG__ 를 실제 값으로)
  sed -e "s/__ACCOUNT__/$ACCOUNT/g" -e "s/__TAG__/$TAG/g" ecs/taskdef-$s.json > /tmp/td-$s.json
  TD=$(aws ecs register-task-definition --cli-input-json file:///tmp/td-$s.json \
        --query taskDefinition.taskDefinitionArn --output text)
  echo "   태스크 정의: $TD"

  # 2) 서비스 생성 — 롤링 업데이트(최소 100%, 최대 200%) + 배포 서킷 브레이커 자동 롤백
  aws ecs create-service --cluster shop --service-name $s \
    --task-definition $TD --desired-count 2 --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$TASK_SG],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=${TG[$s]},containerName=$s,containerPort=${PORT[$s]}" \
    --health-check-grace-period-seconds 20 \
    --deployment-configuration "minimumHealthyPercent=100,maximumPercent=200,deploymentCircuitBreaker={enable=true,rollback=true}" \
    --tags key=Course,value=03 key=Day,value=2 --propagate-tags SERVICE \
    --query 'service.[serviceName,status]' --output text
done

echo "== 안정화 대기 (2~3분)"
aws ecs wait services-stable --cluster shop --services frontend product-api order-api
echo "완료: http://$(out AlbDns)"
