pipeline {
  agent any
  stages {
    stage('init') {
      steps {
        sh 'HOME=./ bundle install'
        sh 'HOME=./ rake test'
        sh './pusher.sh'
        }
      }
    }
    stage('cleanup') {
      steps {
        cleanWs(deleteDirs: true, cleanupMatrixParent: true, cleanWhenUnstable: true, cleanWhenSuccess: true, cleanWhenNotBuilt: true, cleanWhenFailure: true, cleanWhenAborted: true, disableDeferredWipeout: true)
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