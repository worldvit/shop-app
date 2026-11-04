#!/bin/bash
# Day 1 정리 확인 — CloudShell에서 실행
R=ap-northeast-2
run=$(aws ec2 describe-instances --region $R \
  --filters Name=tag:Course,Values=03 Name=instance-state-name,Values=pending,running \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`]|[0].Value]' --output text)
[ -z "$run" ] && echo "[OK] 실행 중인 과정 03 인스턴스 없음 (작업용 EC2는 중지 상태로 보존)" || echo "[남음] 중지할 인스턴스: $run"
st=$(aws cloudformation describe-stacks --region $R --stack-name cicd-workstation --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
[ -n "$st" ] && echo "[유지] cicd-workstation 스택 $st — Day 2에 다시 시작" || echo "[안내] cicd-workstation 스택 없음"
echo "[유지] ECR 저장소는 Day 2에서 사용 (저장 요금은 GB당 소액)"
