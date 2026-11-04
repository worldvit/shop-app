#!/bin/bash
# 심화 2 — CloudWatch 알람 기반 롤백 설정 (CloudShell에서 실행)
# product-api 대상 그룹의 5xx 응답이 1분에 5건 이상이면 ALARM → ECS가 배포를 롤백
set -euo pipefail
export AWS_REGION=ap-northeast-2
out(){ aws cloudformation describe-stacks --stack-name shop-ecs \
  --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text; }
TG=$(out ProductTG); ALB_ARN=$(aws elbv2 describe-load-balancers --names shop-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

aws cloudwatch put-metric-alarm --alarm-name shop-product-api-5xx \
  --namespace AWS/ApplicationELB --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=TargetGroup,Value=${TG##*:} Name=LoadBalancer,Value=${ALB_ARN#*loadbalancer/} \
  --statistic Sum --period 60 --evaluation-periods 1 --threshold 5 \
  --comparison-operator GreaterThanOrEqualToThreshold --treat-missing-data notBreaching \
  --tags Key=Course,Value=03 Key=Day,Value=2
echo "알람 생성: shop-product-api-5xx"

aws ecs update-service --cluster shop --service product-api \
  --deployment-configuration "minimumHealthyPercent=100,maximumPercent=200,deploymentCircuitBreaker={enable=true,rollback=true},alarms={alarmNames=[shop-product-api-5xx],enable=true,rollback=true}" \
  --query 'service.deploymentConfiguration.alarms' --output json
