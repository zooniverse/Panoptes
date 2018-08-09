#!groovy

pipeline {
  agent any

  stages {
    stage('Build Docker image') {
      steps {
        script {
          def dockerRepoName = 'zooniverse/panoptes-jenkins'
          def dockerImageName = "${dockerRepoName}:${BRANCH_NAME}"
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

    stage('Build staging AMIs') {
      when {
        branch 'master'
      }
      agent {
        docker { image 'zooniverse/operations:latest' }
      }
      failFast true
      parallel {
        stage('Build API') {
          steps {
            sh './rebuild.sh panoptes-api-staging'
          }
        }
        stage('Build Dump workers') {
          steps {
            sh './rebuild.sh panoptes-dumpworker-staging'
          }
        }
      }
    }

    stage('Migrate') {
      when {
        branch 'master'
      }
      agent {
        docker { image 'zooniverse/operations:latest' }
      }
      stage('Staging DB') {
        steps {
          sh """#!/bin/bash -e
            source auto_cleanup.sh
            source deploylib.sh
            INSTANCE_ID=\$(./launch_latest.sh -q panoptes-api-staging)
            INSTANCE_DNS_NAME=\$(instance_dns_name \$INSTANCE_ID)
            # Wait for instance/panoptes to come up
            timeout_cmd "timeout 5m ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes true"
            ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes ./migrate.sh
          """
        }
      }
    }

    stage('Deploy staging AMIs') {
      when {
        branch 'master'
      }
      agent {
        docker { image 'zooniverse/operations:latest' }
      }
      failFast true
      parallel {
        stage('Deploy API') {
          steps {
            sh './deploy_latest.sh panoptes-api-staging'
          }
        }
        stage('Deploy Dump workers') {
          steps {
            sh './deploy_latest.sh panoptes-dumpworker-staging'
          }
        }
      }
    }
  }
}