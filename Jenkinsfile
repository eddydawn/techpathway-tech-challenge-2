
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '369607682838'

        ECR_REGISTRY = '369607682838.dkr.ecr.us-east-1.amazonaws.com'

        FRONTEND_REPO = 'techpathway-challenge-2-frontend'
        BACKEND_REPO = 'techpathway-challenge-2-backend'

        ECS_CLUSTER = 'techpathway-challenge-2-cluster'
        FRONTEND_SERVICE = 'techpathway-challenge-2-frontend-service'
        BACKEND_SERVICE = 'techpathway-challenge-2-backend-service'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code downloaded successfully.'
            }
        }

        stage('Test Backend') {
            steps {
                dir('backend') {
                    sh '''
                        docker run --rm \
                          -v "$PWD:/app" \
                          -w /app \
                          node:20-alpine \
                          sh -c "npm ci && npm test -- --runInBand"
                    '''
                }
            }
        }

        stage('Test Frontend') {
            steps {
                dir('frontend') {
                    sh '''
                        docker run --rm \
                          -e CI=true \
                          -v "$PWD:/app" \
                          -w /app \
                          node:20-alpine \
                          sh -c "npm ci && npm test -- --runInBand"
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build \
                      -t $FRONTEND_REPO:$BUILD_NUMBER \
                      -t $FRONTEND_REPO:latest \
                      ./frontend

                    docker build \
                      -t $BACKEND_REPO:$BUILD_NUMBER \
                      -t $BACKEND_REPO:latest \
                      ./backend
                '''
            }
        }

        stage('Login to Amazon ECR') {
            steps {
                sh '''
                    aws ecr get-login-password \
                      --region $AWS_DEFAULT_REGION \
                    | docker login \
                      --username AWS \
                      --password-stdin $ECR_REGISTRY
                '''
            }
        }

        stage('Push Images to ECR') {
            steps {
                sh '''
                    docker tag $FRONTEND_REPO:$BUILD_NUMBER \
                      $ECR_REGISTRY/$FRONTEND_REPO:$BUILD_NUMBER

                    docker tag $FRONTEND_REPO:latest \
                      $ECR_REGISTRY/$FRONTEND_REPO:latest

                    docker tag $BACKEND_REPO:$BUILD_NUMBER \
                      $ECR_REGISTRY/$BACKEND_REPO:$BUILD_NUMBER

                    docker tag $BACKEND_REPO:latest \
                      $ECR_REGISTRY/$BACKEND_REPO:latest

                    docker push $ECR_REGISTRY/$FRONTEND_REPO:$BUILD_NUMBER
                    docker push $ECR_REGISTRY/$FRONTEND_REPO:latest

                    docker push $ECR_REGISTRY/$BACKEND_REPO:$BUILD_NUMBER
                    docker push $ECR_REGISTRY/$BACKEND_REPO:latest
                '''
            }
        }

        stage('Deploy Backend to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                      --cluster $ECS_CLUSTER \
                      --service $BACKEND_SERVICE \
                      --desired-count 1 \
                      --force-new-deployment

                    aws ecs wait services-stable \
                      --cluster $ECS_CLUSTER \
                      --services $BACKEND_SERVICE
                '''
            }
        }

        stage('Deploy Frontend to ECS') {
            steps {
                sh '''
                    aws ecs update-service \
                      --cluster $ECS_CLUSTER \
                      --service $FRONTEND_SERVICE \
                      --desired-count 1 \
                      --force-new-deployment

                    aws ecs wait services-stable \
                      --cluster $ECS_CLUSTER \
                      --services $FRONTEND_SERVICE
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Both applications have been deployed to AWS ECS!'
        }

        failure {
            echo 'FAILED: Check the stage logs to identify the problem.'
        }

        always {
            sh 'docker image prune -f || true'
        }
    }
}
