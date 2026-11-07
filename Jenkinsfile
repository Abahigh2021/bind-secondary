pipeline {
    agent { label 'podman' }

    triggers {
        pollSCM('H/2 * * * *')
    }

    environment {
        REGISTRY = 'registry.assign.aba-hadi.300.ops:5000'
        IMAGE    = "${REGISTRY}/bind-secondary"
        // c1's /tmp is a small RAM disk - keep big temp files on the real disk
        TMPDIR   = '/home/jenkins/tmp'
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

        // BONUS: CVE scan before push.
        // Decision: FAIL the build on HIGH/CRITICAL CVEs that have a fix
        // (--ignore-unfixed), so a vulnerable image never reaches the registry.
        // The report is always saved as a build artifact.
        stage('Scan') {
            steps {
                sh '''
                    mkdir -p "$TMPDIR"
                    podman save -o "$TMPDIR/image.tar" "$IMAGE:$BUILD_NUMBER"
                    trivy image --input "$TMPDIR/image.tar" --scanners vuln \
                        --severity HIGH,CRITICAL --ignore-unfixed --no-progress \
                        --exit-code 1 --output trivy-report.txt
                '''
            }
            post {
                always {
                    sh 'cat trivy-report.txt || true; rm -f "$TMPDIR/image.tar"'
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
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
