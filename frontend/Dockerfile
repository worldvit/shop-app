# frontend: 정적 페이지만 제공. /api/* 경로는 앞단(로컬은 gateway, AWS는 ALB)이 API 서비스로 보낸다.
FROM nginx:1.29-alpine AS base
COPY index.html /usr/share/nginx/html/index.html

# test: nginx 설정 문법 검사
FROM base AS test
RUN nginx -t

FROM base AS runtime
ARG APP_VERSION=v1
RUN sed -i "s/__VERSION__/${APP_VERSION}/" /usr/share/nginx/html/index.html \
 && echo 'ok' > /usr/share/nginx/html/health
EXPOSE 80
