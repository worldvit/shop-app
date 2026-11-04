#!/bin/bash
# Day 3 정리 확인 — CloudShell에서 실행
export AWS_REGION=ap-northeast-2
c=$(aws eks list-clusters --query 'clusters[?@==`shop-eks`]' --output text)
[ -z "$c" ] && echo "[OK] EKS 클러스터 없음" || echo "[남음] shop-eks 클러스터 → bash eks/delete-cluster.sh"
s=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE DELETE_FAILED --query "StackSummaries[?starts_with(StackName,'eksctl-shop-eks')].StackName" --output text)
[ -z "$s" ] && echo "[OK] eksctl 스택 없음" || echo "[남음] 스택: $s"
run=$(aws ec2 describe-instances --filters Name=tag:Course,Values=03 Name=instance-state-name,Values=pending,running --query 'Reservations[].Instances[].InstanceId' --output text)
[ -z "$run" ] && echo "[OK] 실행 중인 과정 03 인스턴스 없음" || echo "[남음] 실행 중: $run (작업용 EC2는 중지, EKS 노드라면 클러스터 삭제 대기)"
