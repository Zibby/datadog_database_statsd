pipeline {
  environment {
    registry = "zibby/datadog_postgres_statsd"
    registryCredential = 'f8a79f84-5ad0-43e4-b32c-87e2c6001a62'
    dockerImage = ''
  }
  agent any
  stages {
    stage('Clone Git') {
      steps {
        git 'https://github.com/Zibby/datadog_database_statsd'
      }
    }
    stage('Build Image') {
      steps {
        script {
          dockerImage = docker.build registry + ":" + "$env.BRANCH_NAME"
        }
      }
    }
    stage('Push') {
      steps {
        script {
          docker.withRegistry( '', registryCredential) {
            dockerImage.push()
          }
        }
      }
    }
  }
  post {
    success {
      slackSend(botUser: true, color: '#36a64f', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
    }
    failure {
      slackSend(botUser: true, color: '#b70000', message: "FAIL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
    }
  }
}
