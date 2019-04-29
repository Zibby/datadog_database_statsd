pipeline {
  agent {
    dockerfile {
      filename 'Dockerfile'
    }

  }
  stages {
   stage('init') {
      steps {
        sh 'HOME=./ bundle install'
      }
    }
    stage('Test') {
      steps {
        sh 'HOME=./ rake test'
      }
    }
  stage('Build') {
    app = docker.build("zibby/datadog_postgres_statsd")
    docker.withRegistry('https://registry.hub.docker.com', 'Dockerhub') {
          app.push("${env.BUILD_NUMBER}")
          app.push("latest")
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
