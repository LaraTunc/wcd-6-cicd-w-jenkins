pipeline {
    agent any

    environment {
        VIRTUALENV = 'venv'
    }
    
    stages {
        stage('Source') {
            steps {
                echo 'Source: Executing Git checkout...'
                // Execute Git checkout of your GitHub repository
                git url: 'https://github.com/LaraTunc/wcd-6-cicd-w-jenkins'
                echo 'Getting requirements'
                script {
                    // Create and activate a virtual environment
                    sh '''
                        python3 -m venv ${VIRTUALENV}
                        . ${VIRTUALENV}/bin/activate
                        pip install -r requirements.txt
                    '''
                }
            }
        }
        stage('Build') {

            environment {
                DOCKER_CRED = credentials('Docker_Cred')
                }

            steps {
                echo 'Build: Building Docker image...'
                sh '''
                    . ${VIRTUALENV}/bin/activate
                    docker login --username ${DOCKER_CRED_USR} --password ${DOCKER_CRED_PSW}
                    docker build -t ${DOCKER_CRED_USR}/webpage:latest -f Dockerfile .
                    docker push ${DOCKER_CRED_USR}/webpage:latest
                '''
            }
        }
   
        stage('Test') {
            steps {
                echo 'In ' + env.BRANCH_NAME + ' branch, testing..'
                script {
                    // Run your test command
                    sh '''
                        . ${VIRTUALENV}/bin/activate
                        python3 -m coverage run test.py
                        python3 -m coverage report
                    '''
                }
                // Stop pipeline if tests fail 
                catchError {
                    error 'Tests failed!'
                }
                
            }
        }

        stage('Push') {

            environment {
                DOCKER_CRED = credentials('Docker_Cred')
                }

            steps {
                echo 'Push: Pushing Docker image...'
                script {
                    // Push the newly built Docker image to Docker Hub repo
                    sh '''
                        . ${VIRTUALENV}/bin/activate
                        docker push ${DOCKER_CRED_USR}/webpage:latest
                    '''
                }
            }
        }

        stage('Deploy'){

            environment {
                DEPLOYMENT_INSTANCE_IP = credentials('Deployment_Instance_IP')
                DOCKER_CRED = credentials('Docker_Cred')
                }
            steps{
                script{
                    echo 'Deploying'

                    sh '''
                        eval "$(ssh-agent -s)"
                        ssh-add ~/.ssh/id_rsa
                        ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOYMENT_INSTANCE_IP "docker ps -a --format '{{.Names}}' | grep -q my-container && docker stop my-container && docker rm my-container || true"
                        ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOYMENT_INSTANCE_IP "docker pull $DOCKER_CRED_USR/webpage:latest && docker run --name my-container -d -p 80:80 $DOCKER_CRED_USR/webpage:latest"
                        '''
                }
            }
        }
    }

}
