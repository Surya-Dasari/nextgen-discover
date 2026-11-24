pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 45, unit: 'MINUTES')
        skipDefaultCheckout(true)
    }

    environment {
        AWS_PROFILE = 'nextgen-jenkins'
        AWS_DEFAULT_REGION = 'us-east-2'
        AWS_REGION = 'us-east-2'
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = '0'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                sh '''
                    echo "===== SOURCE CHECKOUT ====="
                    git rev-parse --short HEAD
                    git status --short
                '''
            }
        }

        stage('Secret Scan - Gitleaks') {
            steps {
                sh '''
                    echo "===== GITLEAKS VERSION ====="
                    gitleaks version

                    echo "===== SECRET SCAN ====="
                    gitleaks git . \
                      --redact \
                      --exit-code 1 \
                      --no-banner
                '''
            }
        }

        stage('Environment Checks') {
            steps {
                sh '''
                    set -eu

                    echo "===== TOOL VERSIONS ====="
                    terraform version
                    aws --version
                    gitleaks version

                    echo "===== AWS IDENTITY ====="
                    aws sts get-caller-identity \
                      --query Arn \
                      --output text
                '''
            }
        }

        stage('Terraform Format Check') {
            steps {
                sh '''
                    terraform fmt -check -recursive infrastructure/terraform
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infrastructure/terraform/infrastructure') {
                    sh '''
                        terraform init \
                          -input=false \
                          -lockfile=readonly
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('infrastructure/terraform/infrastructure') {
                    sh '''
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('infrastructure/terraform/infrastructure') {
                    sh '''
                        terraform plan \
                          -input=false \
                          -no-color \
                          -lock-timeout=5m \
                          -out=tfplan
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully through Terraform Plan.'
        }

        failure {
            echo 'Pipeline failed. Review the failed stage and Jenkins console output.'
        }
    }
}
