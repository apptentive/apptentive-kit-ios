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
    stage('Dev PR') {
      when {
        changeRequest target: 'develop'

        expression {
          env.ENVIRONMENT == 'dev-eks_0'
        }
      }

      stages {
        stage('bundle install') {
          steps {
            script {
              sh 'brew install swift-format'
              sh 'source /Users/ec2-user/.bash_profile && rbenv install --skip-existing && rbenv rehash && which ruby && which gem && gem install bundler:2.2.28 && bundle install'
            }
          }
        }

        stage('clean') {
          steps {
            script {
              sh 'source /Users/ec2-user/.bash_profile &&  bundle exec fastlane clean'
              sh 'source /Users/ec2-user/.bash_profile &&  bundle exec fastlane action clear_derived_data'
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
                      sh 'source /Users/ec2-user/.bash_profile &&  bundle exec fastlane test && bundle exec fastlane coverage'
                    }
                  }
                }
              }
            }

            stage('lint') {
              steps {
                script {
                  sh 'source /Users/ec2-user/.bash_profile &&  bundle exec fastlane lint'
                }
              }
            }
          }
        }

        stage('framework') {
          steps {
            script {
              sh 'source /Users/ec2-user/.bash_profile &&  bundle exec fastlane clean && bundle exec fastlane framework'
            }
          }
        }
      }
    }
  }
}
