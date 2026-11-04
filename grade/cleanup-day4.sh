#!/bin/bash
# 과정 종료 정리 확인 — CloudShell에서 실행
export AWS_REGION=ap-northeast-2
chk(){ [ -z "$2" ] && echo "[OK] $1" || echo "[남음] $1 → $2"; }
chk "EKS 클러스터 없음" "$(aws eks list-clusters --query 'clusters[?@==`shop-eks`]' --output text)"
chk "eksctl·작업용 EC2·ECS 스택 없음" "$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE DELETE_FAILED DELETE_IN_PROGRESS ROLLBACK_COMPLETE --query "StackSummaries[?starts_with(StackName,'eksctl-shop-eks') || StackName=='cicd-workstation' || StackName=='shop-ecs'].StackName" --output text)"
chk "ECR shop/* 저장소 없음" "$(aws ecr describe-repositories --query "repositories[?starts_with(repositoryName,'shop/')].repositoryName" --output text 2>/dev/null)"
chk "과정 03 인스턴스 없음" "$(aws ec2 describe-instances --filters Name=tag:Course,Values=03 Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].InstanceId' --output text)"
chk "ECS 클러스터 없음" "$(aws ecs list-clusters --query 'clusterArns' --output text)"
chk "남은 EBS 볼륨 없음" "$(aws ec2 describe-volumes --filters Name=status,Values=available Name=tag:eks:cluster-name,Values=shop-eks --query 'Volumes[].VolumeId' --output text)"
