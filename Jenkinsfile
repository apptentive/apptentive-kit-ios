pipeline {
  agent {
    label 'apple'
  }

  options {
    timeout(time: 20, unit: 'MINUTES')
  }

  environment {
    GEM_HOME=".gem"
    LC_ALL="en_US.UTF-8"
    LANG="en_US.UTF-8"
  }

  stages {
    stage('Dev (or main) PR') {
      when {
        anyOf {
          changeRequest target: 'develop'
          changeRequest target: 'main'
        }
        expression {
          env.ENVIRONMENT == 'dev-eks_0'
        }
      }
      stages {
        stage('bundle install') {
          steps {
            script {
              sh 'source /Users/ec2-user/.zprofile && rbenv install --skip-existing && rbenv rehash && which ruby && which gem && gem install bundler:2.2.28 && bundle install'
            }
          }
        }

        stage('clean') {
          steps {
            script {
              sh 'source /Users/ec2-user/.zprofile &&  bundle exec fastlane clean'
              sh 'source /Users/ec2-user/.zprofile &&  bundle exec fastlane action clear_derived_data'
            }
          }
        }

        stage('verification') {
          parallel {
            stage('test') {
              steps {
                withCredentials([string(credentialsId: 'iosBuildProdSignature', variable: 'APPTENTIVE_PROD_SIGNATURE')]) {
                  withCredentials([string(credentialsId: 'iosBuildProdKey', variable: 'APPTENTIVE_PROD_KEY')]) {
                    script {
                      sh 'source /Users/ec2-user/.zprofile &&  bundle exec fastlane test'
                    }
                  }
                }
              }
            }

            stage('lint') {
              steps {
                script {
                  sh 'source /Users/ec2-user/.zprofile &&  bundle exec fastlane lint'
                }
              }
            }
          }
        }

        stage('framework') {
          steps {
            script {
              sh 'source /Users/ec2-user/.zprofile &&  bundle exec fastlane clean && bundle exec fastlane framework'
            }
          }
        }
      }
    }
  }
}
