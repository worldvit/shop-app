# shop-app

CI/CD 실습용 샘플 앱 (3서비스). 강사 템플릿 저장소이며, 수강생은 **Use this template**으로 자기 GitHub에 복제해 쓴다.

| 폴더 | 내용 |
|---|---|
| `frontend/` | nginx 정적 페이지 (`/`) |
| `product-api/` | Flask + SQLite 상품 API (`/api/products`) |
| `order-api/` | Flask + SQLite 주문 API (`/api/orders`) |
| `gateway/` | 로컬 전용 경로 라우터 (AWS의 ALB 역할) |
| `jenkins/` | 실습용 Jenkins 이미지·실행 스크립트, webhook 중계 스크립트 |
| `infra/` | 작업용 EC2 CloudFormation 템플릿 |
| `solutions/dayN/` | 일차별 정답 파일 (처음부터 공개) |
| `grade/` | 일차별 채점·정리 확인 스크립트 |
| `rescue/` | 앞 실습을 못 끝냈을 때 다음 실습 시작점 스크립트 |

## 로컬 실행
```bash
docker compose up -d --build
curl localhost:8000/api/products
```

## 테스트
각 Dockerfile의 `test` 단계에서 실행된다. 테스트가 실패하면 이미지가 만들어지지 않는다.
```bash
docker build --target test product-api
```

모든 응답에 `X-App-Version` 헤더가 붙는다. 이미지 빌드 때 `APP_VERSION`(커밋 해시)이 들어가므로, 배포 중 어떤 버전이 응답했는지 확인할 수 있다.
