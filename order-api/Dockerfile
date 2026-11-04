# 1단계 base: 앱 실행에 필요한 패키지
FROM python:3.13-slim AS base
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

# 2단계 test: 단위 테스트 실행 (실패하면 빌드 중단)
FROM base AS test
COPY requirements-dev.txt test_app.py ./
RUN pip install --no-cache-dir -r requirements-dev.txt && python -m pytest -q

# 3단계 runtime: 배포용 이미지 (테스트 도구 제외)
FROM base AS runtime
ARG APP_VERSION=v1
ENV APP_VERSION=${APP_VERSION}
RUN useradd -u 10001 app
USER app
EXPOSE 5000
CMD ["gunicorn", "-b", "0.0.0.0:5000", "-w", "2", "app:app"]
