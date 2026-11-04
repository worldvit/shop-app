#!/usr/bin/env bash
# 작업용 EC2에서 실행: Jenkins 이미지 빌드 → 컨테이너 시작
set -euo pipefail
cd "$(dirname "$0")"

sudo mkdir -p /var/jenkins_home && sudo chown 1000:1000 /var/jenkins_home
docker build -t cicd-jenkins .

docker rm -f jenkins 2>/dev/null || true
docker run -d --name jenkins --restart unless-stopped \
  -p 8080:8080 \
  -v /var/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "$(stat -c %g /var/run/docker.sock)" \
  cicd-jenkins

echo "초기 관리자 비밀번호 (1~2분 뒤 확인):"
echo "  docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
