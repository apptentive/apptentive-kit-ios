pipeline {
  agent {
    label 'macos'
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
          env.ENVIRONMENT == 'dev'
        }
      }

      stages {
        stage('bundle install') {
          steps {
            script {
              sh 'gem install bundler:2.2.28 && bundle install'
            }
          }
        }
        
        stage('clean') {
          steps {
            script {
              sh 'bundle exec fastlane clean'
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
                      sh 'bundle exec fastlane test && bundle exec fastlane coverage'
                    }
                  }
                }
              }
            }

            stage('lint') {
              steps {
                script {
                  sh 'bundle exec fastlane lint'
                }
              }
            }
          }
        }

        stage('framework') {
          steps {
            script {
              sh 'bundle exec fastlane clean && bundle exec fastlane framework'
            }
          }
        }
      }
    }
  }
}
