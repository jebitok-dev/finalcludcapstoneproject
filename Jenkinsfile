pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Unit Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Integraton Test') {
            steps {
                sh 'mvn integration-test'
            }
        }

        stage('Security Scan') {
            steps {
                sh 'zap-cli quick-scan --self-contained --start-options "-config api.disablekey=true" $APP_URL'
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh 'kubectl apply -f k8s/staging'
            }
        }

        stage('Performance Tests') {
            steps {
                sh 'jmeter -n -t performance-tests/load-test.jmx -l results.jtl'
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }

            steps {
                sh 'kubectl apply -f k8s/production'
            }
        }
    }

    post {
        always {
            juint '**/target/surefire-reports/TEST-*-xml'
            archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
        }
    }
}