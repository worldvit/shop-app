#!/bin/bash
# order-api를 ECS 자체 블루/그린 배포로 전환 — CloudShell에서 실행 (심화 1 · 강사 시연)
# 운영 리스너(:80) /api/orders* 규칙과 테스트 리스너(:8080) 규칙, 그린 대상 그룹, 인프라 역할은 shop-ecs 스택에 이미 있다.
set -euo pipefail
export AWS_REGION=ap-northeast-2
out(){ aws cloudformation describe-stacks --stack-name shop-ecs \
  --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text; }
BAKE=${1:-3}   # 베이크 시간(분)

aws ecs update-service --cluster shop --service order-api \
  --deployment-configuration "strategy=BLUE_GREEN,bakeTimeInMinutes=$BAKE,minimumHealthyPercent=100,maximumPercent=200,deploymentCircuitBreaker={enable=true,rollback=true}" \
  --load-balancers "[{\"targetGroupArn\":\"$(out OrderBlueTG)\",\"containerName\":\"order-api\",\"containerPort\":5000,
     \"advancedConfiguration\":{\"alternateTargetGroupArn\":\"$(out OrderGreenTG)\",
       \"productionListenerRule\":\"$(out OrderRule)\",\"testListenerRule\":\"$(out OrderTestRule)\",
       \"roleArn\":\"$(out EcsInfraRoleArn)\"}}]" \
  --query 'service.deploymentConfiguration.[strategy,bakeTimeInMinutes]' --output text

echo "전환 완료. 이후 order-api 배포는 블루/그린으로 진행된다."
echo "운영 확인:   curl -s http://$(out AlbDns)/api/orders/health"
echo "테스트 확인: curl -s http://$(out AlbDns):8080/api/orders/health   (배포 중 그린 버전만 응답)"
