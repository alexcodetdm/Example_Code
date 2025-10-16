// Jenkinsfile (Declarative Pipeline)
pipeline {
    agent any // Запускать на любом доступном агенте
    triggers {
        GenericTrigger(
            genericVariables: [
                [key: 'REF', value: '$.ref']
            ],
            causeString: 'Triggered by Bitbucket',
            token: 'your-secret-token', // Создайте любой сложный token
            printContributedVariables: true,
            printPostContent: true
        )
    }
    stages {
        stage('Build') {
            steps {
                echo 'Собираем проект...'
                // Например, для Node.js:
                // sh 'npm install'
                // sh 'npm run build'
                
                // Или для Java/Maven:
                // sh 'mvn compile'
            }
        }
        stage('Test') {
            steps {
                echo 'Запускаем тесты...'
                // sh 'npm test'
                // sh 'mvn test'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Деплоим артефакт...'
                // Здесь могут быть команды для загрузки куда-либо
            }
        }
    }
}