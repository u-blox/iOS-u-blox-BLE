node('iOS') {
    stage('Checkout') {
        checkout scm
    }

    stage('Update Dependencies') {
        sh 'carthage update'
    }

    stage('Build') {
        sh 'xcodebuild -scheme "U-blox" -configuration "Debug" build -destination "platform=iOS Simulator,name=iPhone 6,OS=11.4" | /usr/local/bin/xcpretty -r junit && exit ${PIPESTATUS[0]}'

        step([$class: 'JUnitResultArchiver', allowEmptyResults: true, testResults: 'build/reports/junit.xml'])
    }
}
