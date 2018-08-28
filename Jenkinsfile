#!groovy

pipeline {
  agent none

  stages {
    stage('Build Docker image') {
      agent any
      steps {
        script {
          def dockerRepoName = 'zooniverse/panoptes'
          def dockerImageName = "${dockerRepoName}:${BRANCH_NAME}"
          def newImage = docker.build(dockerImageName)
          newImage.push()

          if (BRANCH_NAME == 'master') {
            stage('Update latest tag') {
              newImage.push('latest')
            }
          }

          def tag = sh(returnStdout: true, script: "git tag --contains | head -1").trim()
          if (tag == 'production') {
            stage('Update production tag') {
              newImage.push('production')
            }
          }
        }
      }
    }

    stage('Build AMIs') {
      failFast true
      parallel {
        stage('Staging API') {
          when { branch 'master' }
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./rebuild.sh panoptes-api-staging
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
        stage('Staging Dump workers') {
          when { branch 'master' }
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./rebuild.sh panoptes-dumpworker-staging
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
        stage('Production API') {
          when { tag 'production' }
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./rebuild.sh panoptes-api
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
        stage('Production Dump workers') {
          when { tag 'production' }
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./rebuild.sh panoptes-dumpworker
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
      }
    }

    stage('Migrate Staging DB') {
      when { branch 'master' }
      options {
        skipDefaultCheckout true
      }
      agent {
        docker {
          image 'zooniverse/operations:latest'
          args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
        }
      }
      steps {
        sh """#!/bin/bash -e
          while true; do sleep 3; echo -n "."; done &
          KEEP_ALIVE_ECHO_JOB=\$!
          cd /operations
          source auto_cleanup.sh
          source deploylib.sh
          INSTANCE_ID=\$(./launch_latest.sh -q panoptes-api-staging)
          INSTANCE_DNS_NAME=\$(instance_dns_name \$INSTANCE_ID)
          # Wait for instance/panoptes to come up
          timeout_cmd "timeout 5m ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes true"
          ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes ./migrate.sh
          kill \${KEEP_ALIVE_ECHO_JOB}
        """
      }
    }

    stage('Deploy staging AMIs') {
      when { branch 'master' }
      failFast true
      parallel {
        stage('Deploy API') {
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./deploy_latest.sh panoptes-api-staging
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
        stage('Deploy Dump workers') {
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./deploy_latest.sh panoptes-dumpworker-staging
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
      }
    }
  }
}
