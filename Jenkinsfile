pipeline {
    agent { label 'podman' }

    triggers {
        pollSCM('H/2 * * * *')
    }

    environment {
        REGISTRY = 'registry.assign.aba-hadi.300.ops:5000'
        IMAGE    = "${REGISTRY}/bind-secondary"
    }

    stages {
        stage('Build') {
            steps {
                withCredentials([file(credentialsId: 'bind-xfer-key', variable: 'XFER_KEY')]) {
                    sh '''
                        cp "$XFER_KEY" xfer.key
                        podman build -t "$IMAGE:$BUILD_NUMBER" .
                        rm -f xfer.key
                    '''
                }
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'registry-creds',
                                                  usernameVariable: 'REG_USER',
                                                  passwordVariable: 'REG_PASS')]) {
                    sh '''
                        echo "$REG_PASS" | podman login --username "$REG_USER" --password-stdin "$REGISTRY"
                        SHORT_SHA=$(git rev-parse --short HEAD)
                        podman tag "$IMAGE:$BUILD_NUMBER" "$IMAGE:$SHORT_SHA"
                        podman push "$IMAGE:$BUILD_NUMBER"
                        podman push "$IMAGE:$SHORT_SHA"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'rm -f xfer.key; podman logout "$REGISTRY" || true'
        }
    }
}
