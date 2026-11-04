#!/bin/bash
# Argo CD UI를 작업용 EC2의 8081 포트로 연다 (보안 그룹이 내 IP에만 열려 있음)
pkill -f 'port-forward.*argocd-server' 2>/dev/null || true
nohup kubectl port-forward --address 0.0.0.0 -n argocd svc/argocd-server 8081:443 >/tmp/argocd-pf.log 2>&1 &
sleep 2
IP=$(TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 60'); \
     curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Argo CD UI : https://$IP:8081   (인증서 경고 → 고급 → 계속)"
echo "아이디     : admin"
echo "비밀번호   : $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
