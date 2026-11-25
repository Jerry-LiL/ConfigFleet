// Gate every change: ansible-lint, syntax checks, then a --check --diff dry run.
pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Inventory to dry-run'
        )
    }

    environment {
        ANSIBLE_CONFIG = "${WORKSPACE}/ansible.cfg"
        ANSIBLE_FORCE_COLOR = '1'
    }

    stages {
        stage('Prepare') {
            steps {
                withCredentials([file(credentialsId: 'configfleet-vault-password', variable: 'VAULT_PASSWORD_FILE')]) {
                    sh 'install -m 600 "$VAULT_PASSWORD_FILE" .vault_pass'
                }
                sh 'ansible-galaxy collection install -r requirements.yml -p collections'
            }
        }

        stage('Lint') {
            steps {
                sh 'scripts/lint.sh'
            }
        }

        stage('Syntax check') {
            steps {
                sh 'scripts/syntax-check.sh'
            }
        }

        stage('Dry run') {
            steps {
                sh 'scripts/dry-run.sh --inventory "inventories/${ENVIRONMENT}"'
            }
        }
    }

    post {
        always {
            sh 'rm -f .vault_pass'
        }
    }
}
