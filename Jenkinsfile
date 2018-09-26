properties([[$class: 'BuildDiscarderProperty',
            strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '1', daysToKeepStr: '60', numToKeepStr: '60']],
            [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
            [$class: 'ParametersDefinitionProperty', parameterDefinitions: [
            [$class: 'StringParameterDefinition', defaultValue: '6.0-SNAPSHOT', description: 'Product version to build', name: 'NUXEO_VERSION'],
            [$class: 'StringParameterDefinition', defaultValue: '', description: 'Optional - Use the specified URL (eg a link to staging) as the source for the distribution instead of maven', name: 'DISTRIBUTION_URL'],
            [$class: 'BooleanParameterDefinition', defaultValue: true, description: 'Build .exe package', name: 'BUILD_EXE'],
            [$class: 'BooleanParameterDefinition', defaultValue: true, description: 'Publish .exe package', name: 'PUBLISH_EXE'],
            [$class: 'StringParameterDefinition', defaultValue: '/var/www/community.nuxeo.com/static/staging/', description: 'Staging publishing destination path (for scp)', name: 'STAGING_PATH'],
            [$class: 'StringParameterDefinition', defaultValue: 'nuxeo@lethe.nuxeo.com', description: 'Publishing destination host (for scp)', name: 'DEPLOY_HOST']]],
            pipelineTriggers([])])

node('OLDJOYEUX') {
    timestamps {
        timeout(time: 240, unit: 'MINUTES') {
            sh '''
                #!/bin/bash -ex

                if [ -n "$DISTRIBUTION_URL" ]; then
                    DISTRIBUTION="-Ddistribution.archive=$DISTRIBUTION_URL"
                else
                    DISTRIBUTION=""
                fi

                if [ "$BUILD_EXE" = "true" ]; then

                    echo "*** "$(date +"%H:%M:%S")" Cloning/updating nuxeo-packaging-windows"
                    if [ ! -d nuxeo-packaging-windows ]; then
                        git clone git@github.com:nuxeo/nuxeo-packaging-windows.git
                    fi
                    cd nuxeo-packaging-windows

                    git pull

                    if [ "$PUBLISH_EXE" = "true" ]; then
                        echo "*** "$(date +"%H:%M:%S")" Building and publishing .exe package"
                        mvn clean package -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION -Ddeploy.host=${DEPLOY_HOST} -Ddeploy.path=$STAGING_PATH
                        echo "*** "$(date +"%H:%M:%S")" Publishing .exe package to staging"
                        PKG=$(find . -name 'nuxeo-*-setup.exe' -print | head -n 1)
                        FILENAME=$(basename $PKG)
                        scp $PKG ${DEPLOY_HOST}:$STAGING_PATH
                        echo "*** "$(date +"%H:%M:%S")" Generating .exe package signatures on staging"
                        ssh ${DEPLOY_HOST} "cd $STAGING_PATH && md5sum $FILENAME > ${FILENAME}.md5 && sha256sum $FILENAME > ${FILENAME}.sha256"
                    else
                        echo "*** "$(date +"%H:%M:%S")" Building .exe package"
                        mvn clean package -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION
                    fi
                fi
                '''
        }
    }
}
