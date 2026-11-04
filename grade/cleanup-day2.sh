#!/bin/bash
# Day 2 정리 확인 — CloudShell에서 실행
export AWS_REGION=ap-northeast-2
st=$(aws cloudformation describe-stacks --stack-name shop-ecs --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
[ -z "$st" ] && echo "[OK] shop-ecs 스택 없음 (ALB·클러스터 삭제됨)" || echo "[남음] shop-ecs 스택 상태 $st → bash ecs/cleanup.sh"
lb=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='shop-alb'].LoadBalancerName" --output text 2>/dev/null)
[ -z "$lb" ] && echo "[OK] ALB 없음" || echo "[남음] ALB $lb"
run=$(aws ec2 describe-instances --filters Name=tag:Course,Values=03 Name=instance-state-name,Values=pending,running --query 'Reservations[].Instances[].InstanceId' --output text)
[ -z "$run" ] && echo "[OK] 실행 중인 작업용 EC2 없음" || echo "[남음] 중지할 인스턴스: $run"
