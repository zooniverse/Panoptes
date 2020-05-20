#!groovy

pipeline {
  agent none

  options {
    quietPeriod(120)
    disableConcurrentBuilds()
  }

  stages {
    stage('Update documentation site') {
      when { branch 'master' }
      agent {
        dockerfile {
          filename 'Dockerfile.docs'
          args "-v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -v /etc/shadow:/etc/shadow:ro -u root"
        }
      }

      steps {
        sh "cd /src/docs && git config remote.origin.url git@github.com:zooniverse/panoptes.git"
        sh "cd /src/docs && git config --global user.email jenkins@zooniverse.org"
        sh "cd /src/docs && git config --global user.name Zooniverse Jenkins"
        sshagent(credentials: ["cd5582ce-30e3-49bb-8b04-a1a5d1ff7b56"]) {
          sh "cd /src/docs && ls -al && ./deploy.sh"
        }
      }
    }

    stage('Build Docker image') {
      agent any
      steps {
        script {
          def dockerRepoName = 'zooniverse/panoptes'
          def dockerImageName = "${dockerRepoName}:${GIT_COMMIT}"
          def newImage = docker.build(dockerImageName)
          newImage.push()

          if (BRANCH_NAME == 'master') {
            stage('Update latest tag') {
              newImage.push('latest')
            }
          }
        }
      }
    }

    stage('Deploy production to Kubernetes') {
      when { tag 'production-kubernetes' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-production.tmpl | kubectl --context azure apply --record -f -"
      }
      post {
        success {
          script {
            if (env.TAG_NAME == 'production-kubernetes') {
              slackSend (
                color: '#00FF00',
                message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                channel: "#ops"
              )
            }
          }
        }

        failure {
          script {
            if (env.TAG_NAME == 'production-kubernetes') {
              slackSend (
                color: '#FF0000',
                message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                channel: "#ops"
              )
            }
          }
        }
      }
    }

    stage('Deploy staging to Kubernetes') {
      when { branch 'master' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-staging.tmpl | kubectl --context azure apply --record -f -"
      }
      post {
        success {
          script {
            if (env.BRANCH_NAME == 'master') {
              slackSend (
                color: '#00FF00',
                message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                channel: "#ops"
              )
            }
          }
        }

        failure {
          script {
            if (env.BRANCH_NAME == 'master') {
              slackSend (
                color: '#FF0000',
                message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                channel: "#ops"
              )
            }
          }
        }
      }
    }
  }
}
