// Day 1 시작 코드: 3서비스 단위 테스트만 실행한다.
// 테스트는 각 Dockerfile의 test 단계(docker build --target test)에서 돈다.
pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('Test') {
      parallel {
        stage('frontend')    { steps { sh 'docker build --target test -t test-frontend frontend' } }
        stage('product-api') { steps { sh 'docker build --target test -t test-product-api product-api' } }
        stage('order-api')   { steps { sh 'docker build --target test -t test-order-api order-api' } }
      }
    }
    // TODO(실습 ③): Build·Push 단계를 여기에 추가한다.
  }
}
