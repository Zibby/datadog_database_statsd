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
    stage('test') {
      steps {
        sh 'HOME=./ rake test'
      }
    }
    stage('build-docker-image') {
      steps {
        withDockerRegistry([credentialsId: 'f8a79f84-5ad0-43e4-b32c-87e2c6001a62', url: 'registry.hub.docker.com']) {
          def app = docker.build("zibby/datadog_postgres_statsd")
          app.push()
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
