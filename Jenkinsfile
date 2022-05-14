def getVersion(){
    def commitHash =  sh returnStdout: true, script: 'git rev-parse --short HEAD'
    return commitHash
}
pipeline{
    agent any

    options{
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
    }

    environment{
        GIT_COMMIT_HASH = getVersion()
        host = "$host"
        sonar_pass = "$sonar_pass"
        sonar_user = "$sonar_user"
    }

    stages{
        stage("Code checkout"){
            steps{
                echo "[INFO] Checking out latest code from git"
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/Microservices-starter/zuul-api-gateway.git'                
            }
        }

        stage("Unit Tests"){
            steps{
                echo "[INFO] Performing tests"
                sh 'mvn clean test'
            }
        }

        stage("Sonar analysis"){
            steps{
                echo "[INFO] Performing analysis with Sonarqube"
                script{
                    withSonarQubeEnv(credentialsId: 'sonartoken'){
                        sh 'mvn clean verify sonar:sonar -Dsonar.host.url=$host -Dsonar.login=$sonar_user -Dsonar.password=$sonar_pass'
                        sh 'cat target/sonar/report-task.txt'
                    }
                }
            }

        }

        stage("Quality Gates"){
            steps{
                echo "[INFO] Verifying Quality gates"
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Docker build"){
            steps{
                echo "[INFO] Building Docker images"
                sh 'docker build -t rajputmarch2020/zuul_apigw:$GIT_COMMIT_HASH .'
            }
        }

        stage("Trivy Scan"){
            steps{
                echo "[INFO] Scanning image with Trivy"
                sh 'trivy image rajputmarch2020/zuul_apigw:$GIT_COMMIT_HASH'
            }
        }

        stage("Docker push"){
            steps{
                echo "[INFO] Pushing Docker images to Dockerhub"
                withCredentials([string(credentialsId: 'dockerhub', variable: 'password')]){
                    sh 'docker login -u rajputmarch2020 -p ${password} '
                }
                    sh 'docker push rajputmarch2020/zuul_apigw:$GIT_COMMIT_HASH'
            }
        }

        stage("Teardown"){
            steps{
                echo "[INFO] Deleting Docker images after pushed to Dockerhub"
                sh ''' 
                  docker rmi rajputmarch2020/zuul_apigw:$GIT_COMMIT_HASH
                  docker image prune -f
                '''
            }
        }

        stage("Helm charts Config check"){
            steps{
                echo "[INFO] Checking Helm chart config"
                script{
                    dir('helm-charts'){
                        withEnv(['DATREE_TOKEN=ao1RpL3G3LMRL6eucy37hv']){
                            sh 'helm datree test zuul/'
                        }
                    }
                }
            }
        }

        stage("Approval"){
            steps{
                script{
                    timeout(10) {
                        mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> Go to build url and approve the deployment request <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "ravisinghrajput005@gmail.com";  
                        input(id: "Deploy Gate", message: "Deploy ${params.project_name}?", ok: 'Deploy')
                    }
                }
            }
        }

        stage("Deploy to Kubernetes cluster"){
            steps{
                script{
                    withCredentials([kubeconfigFile(credentialsId: 'kubernetes-config', variable: 'KUBECONFIG')]) {
                        dir("helm-charts/zuul"){
                            sh 'helm upgrade --install --set image.repository="rajputmarch2020/zuul_apigw" --set image.tag="${GIT_COMMIT_HASH}" zuul zuul/ ' 
                        }
                    }
                }
            }
        }
    }

    post{
        always{
            mail bcc: '', body: "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "${currentBuild.result} CI: Project name -> ${env.JOB_NAME}", to: "ravisinghrajput005@gmail.com";  
        }
        success{
            echo "[SUCCESS] Pipeline executed successfully"
            slackSend color: "good", message: "Status: Pipeline executed successfully  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        failure{
            echo "[FAILED] pipeline execution failed"
            slackSend color: "danger", message: "Status: pipeline execution failed | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} 
        }
        changed{
            echo "[UNSTABLE] Build is Changed"
            slackSend color: "yellow", message: "Status: Build is changed from the previous.  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        unstable{
            echo "[UNSTABLE] Build is unstable"
            slackSend color: "yellow", message: "Status: Build is unstable  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
        aborted{
            echo "[ABORTED] Build was aborted"
            slackSend color: "yellow", message: "Status: Build was aborted  | Job: ${env.JOB_NAME} | Build number ${env.BUILD_NUMBER} "
        }
    }
}