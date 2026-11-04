#!/usr/bin/env bash
# GitHub webhook 중계: smee.io 채널로 온 알림을 로컬 Jenkins로 넘긴다.
# 사용법: ./run-smee.sh https://smee.io/<채널ID>
set -euo pipefail
URL="${1:?smee 채널 주소를 인자로 주세요 (https://smee.io/...)}"

docker rm -f smee 2>/dev/null || true
docker run -d --name smee --restart unless-stopped --network host \
  node:22-alpine npx --yes smee-client -u "$URL" -t http://localhost:8080/github-webhook/
docker logs -f smee
