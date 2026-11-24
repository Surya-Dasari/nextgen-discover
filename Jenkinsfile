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
                    terraform fmt -recursive infrastructure/terraform
                    terraform fmt -check -recursive infrastructure/terraform
                '''
            }
        }

        stage('Terraform Security Scan') {
            steps {
                sh '''
                    set -eu

                    echo "===== TERRAFORM SECURITY SCAN ====="

                    trivy config \\
                      --severity HIGH,CRITICAL \\
                      --exit-code 1 \\
                      infrastructure/terraform/infrastructure

                    echo "SUCCESS: Terraform security scan completed."
                '''
            }
        }

        stage('Terraform Backend Readiness Check') {
            steps {
                sh '''
                    set -eu

                    echo "===== CHECKING S3 TERRAFORM BACKEND ====="

                    aws s3api head-bucket \
                      --bucket nextgen-discover-terraform-state-659071697866-us-east-2

                    echo "SUCCESS: S3 backend bucket exists and is accessible."
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('infrastructure/terraform/infrastructure') {
                    sh '''
                        terraform init \
                          -input=false \
                          -lockfile=readonly \
                          -backend-config="bucket=nextgen-discover-terraform-state-659071697866-us-east-2" \
                          -backend-config="key=infrastructure/terraform.tfstate" \
                          -backend-config="region=us-east-2" \
                          -backend-config="encrypt=true" \
                          -backend-config="use_lockfile=true"
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
                        set +x
                        set -eu

                        echo "===== RETRIEVING JWT PUBLIC KEY ====="

                        command -v python3 >/dev/null 2>&1 || {
                            echo "ERROR: Python3 is required."
                            exit 1
                        }

                        export TF_VAR_jwt_public_key_pem="$(
                            aws secretsmanager get-secret-value \\
                              --secret-id nextgen-discover/jwt \\
                              --region "$AWS_REGION" \\
                              --profile "$AWS_PROFILE" \\
                              --query SecretString \\
                              --output text |
                            python3 -c 'import json,sys; print(json.load(sys.stdin)["jwt_public_key_pem"], end="")'
                        )"

                        if [ -z "$TF_VAR_jwt_public_key_pem" ]; then
                            echo "ERROR: JWT public key retrieval failed."
                            exit 1
                        fi

                        echo "SUCCESS: JWT public key retrieved."

                        # Supply JWT validation claims required by Terraform.
                        export TF_VAR_jwt_issuer="nextgen-discover-auth"
                        export TF_VAR_jwt_audience="nextgen-discover-api"

                        echo "SUCCESS: JWT issuer and audience configured."


                        terraform plan \\
                          -input=false \\
                          -no-color \\
                          -lock-timeout=5m \\
                          -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Review the Terraform plan. Approve to create or modify AWS infrastructure?',
                        ok: 'Approve Terraform Apply'
                    )
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('infrastructure/terraform/infrastructure') {
                    sh """
                        set -eu

                        if [ ! -f tfplan ]; then
                            echo "ERROR: Terraform plan file not found."
                            exit 1
                        fi

                        terraform apply \
                          -input=false \
                          -no-color \
                          -lock-timeout=5m \
                          tfplan
                    """
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
