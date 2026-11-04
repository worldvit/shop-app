// Day 1 정답: 테스트 → 이미지 빌드 → ECR 푸시 (태그 = git 커밋 해시 7자리)
def SERVICES = ['frontend', 'product-api', 'order-api']

def buildAndPush(String svc) {
  sh """
    docker build --target runtime --build-arg APP_VERSION=${env.TAG} \
      -t ${env.REGISTRY}/shop/${svc}:${env.TAG} ${svc}
    docker push ${env.REGISTRY}/shop/${svc}:${env.TAG}
  """
}

pipeline {
  agent any
  options { timestamps() }
  environment {
    AWS_REGION = 'ap-northeast-2'
  }

  stages {
    stage('Test') {
      parallel {
        stage('frontend')    { steps { sh 'docker build --target test -t test-frontend frontend' } }
        stage('product-api') { steps { sh 'docker build --target test -t test-product-api product-api' } }
        stage('order-api')   { steps { sh 'docker build --target test -t test-order-api order-api' } }
      }
    }

    stage('ECR Login') {
      steps {
        script {
          def account = sh(returnStdout: true, script: 'aws sts get-caller-identity --query Account --output text').trim()
          env.REGISTRY = "${account}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
          env.TAG = env.GIT_COMMIT.take(7)
        }
        sh 'aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY'
      }
    }

    stage('Build & Push') {
      steps {
        script {
          parallel SERVICES.collectEntries { svc -> [(svc): { buildAndPush(svc) }] }
        }
      }
    }
  }

  post {
    success { echo "푸시 완료: shop/*:${env.TAG}" }
  }
}
