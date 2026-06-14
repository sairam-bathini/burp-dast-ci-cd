// Jenkinsfile (Declarative Pipeline) for integration of Dastardly, from Burp Suite.

pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    
    environment {
        WORKSPACE_DIR = "${WORKSPACE}"
        REPORT_FILE = "${WORKSPACE_DIR}/dastardly-report.xml"
        BURP_URL = 'https://ginandjuice.shop/'
        DASTARDLY_IMAGE = 'public.ecr.aws/portswigger/dastardly:latest'
    }
    
    stages {
        stage('Preparation') {
            steps {
                script {
                    echo 'Starting Burp Suite Dastardly Integration Pipeline'
                    sh 'echo "Workspace: ${WORKSPACE_DIR}"'
                }
            }
        }
        
        stage('Docker Pull Dastardly from Burp Suite container image') {
            steps {
                script {
                    echo 'Pulling latest Dastardly image...'
                    sh 'docker pull ${DASTARDLY_IMAGE}'
                }
            }
        }
        
        stage('Docker run Dastardly from Burp Suite Scan') {
            steps {
                script {
                    echo 'Running Dastardly security scan...'
                    // Clean workspace before scan
                    deleteDir()
                    
                    // Run Dastardly scan in Docker
                    sh '''
                        mkdir -p "${WORKSPACE_DIR}"
                        docker run --rm \
                            --user $(id -u):$(id -g) \
                            -v ${WORKSPACE_DIR}:${WORKSPACE_DIR}:rw \
                            -e BURP_START_URL=${BURP_URL} \
                            -e BURP_REPORT_FILE_PATH=${REPORT_FILE} \
                            ${DASTARDLY_IMAGE}
                    '''
                }
            }
        }
        
        stage('Verify Report Generation') {
            steps {
                script {
                    echo 'Verifying scan report was generated...'
                    sh '''
                        if [ -f "${REPORT_FILE}" ]; then
                            echo "Report found at: ${REPORT_FILE}"
                            ls -lah "${REPORT_FILE}"
                        else
                            echo "ERROR: Report file not found at ${REPORT_FILE}"
                            echo "Contents of workspace:"
                            ls -lah "${WORKSPACE_DIR}"
                            exit 1
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo 'Publishing test results...'
            }
            // Publish JUnit results if report exists
            junit testResults: 'dastardly-report.xml', 
                  allowEmptyResults: true, 
                  skipPublishingChecks: true
        }
        
        success {
            echo 'Pipeline completed successfully!'
        }
        
        failure {
            script {
                echo 'Pipeline failed! Check logs for details.'
                // Debug: List workspace contents on failure
                sh 'ls -lah ${WORKSPACE_DIR} || true'
            }
        }
        
        unstable {
            echo 'Pipeline unstable - security vulnerabilities detected'
        }
        
        cleanup {
            script {
                echo 'Cleaning up Docker resources...'
                // Optional: Remove dangling images
                sh 'docker image prune -f --filter "dangling=true" || true'
            }
        }
    }
}
