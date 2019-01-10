/*
 * (C) Copyright ${year} Nuxeo (http://nuxeo.com/) and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors:
 *     mguillaume
 *     atimic
 */

properties([[$class: 'BuildDiscarderProperty',
            strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '1', daysToKeepStr: '60', numToKeepStr: '60']],
            [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
            [$class: 'ParametersDefinitionProperty', parameterDefinitions: [
            [$class: 'StringParameterDefinition', defaultValue: '6.0-SNAPSHOT', description: 'Product version to build', name: 'NUXEO_VERSION'],
            [$class: 'StringParameterDefinition', defaultValue: '', description: 'Optional - Alternate URL to download the distribution from instead of the default Maven artifact download. For instance: http://community.nuxeo.com/static/snapshots/nuxeo-server-tomcat-10.3-SNAPSHOT.zip', name: 'DISTRIBUTION_URL'],
            [$class: 'BooleanParameterDefinition', defaultValue: true, description: 'Publish .exe package', name: 'PUBLISH_EXE'],
            [$class: 'StringParameterDefinition', defaultValue: '/var/www/community.nuxeo.com/static/staging/', description: 'Staging publishing destination path (for scp)', name: 'STAGING_PATH'],
            [$class: 'StringParameterDefinition', defaultValue: 'nuxeo@lethe.nuxeo.com', description: 'Publishing destination host (for scp)', name: 'DEPLOY_HOST']]],
            ])

node('SLAVE') {
  timestamps {
    timeout(time: 240, unit: 'MINUTES') {
      checkout([$class: 'GitSCM', branches: [[name: '*/feature-NXBT-2399-split&fix']], browser: [$class: 'GithubWeb', repoUrl: 'https://github.com/nuxeo/nuxeo-packaging-windows'], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'PathRestriction', excludedRegions: '3rdparties/.*', includedRegions: '']], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/nuxeo/nuxeo-packaging-windows']]])
      sh '''#!/bin/bash -ex
        MAVEN_OPTS="-Xmx512m -Xmx2048m"
        if [ -n "$DISTRIBUTION_URL" ]; then
          DISTRIBUTION_OPTS="-Ddistribution.archive=$DISTRIBUTION_URL"
        else
          DISTRIBUTION_OPTS=""
        fi

        if [ "$PUBLISH_EXE" = "true" ]; then
          echo "*** "$(date +"%H:%M:%S")" Building and publishing .exe package"
          mvn clean package -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION_OPTS -Ddeploy.host=${DEPLOY_HOST} -Ddeploy.path=$STAGING_PATH
          echo "*** "$(date +"%H:%M:%S")" Publishing .exe package to staging"
          PKG=$(find . -name 'nuxeo-*-setup.exe' -print | head -n 1)
          FILENAME=$(basename $PKG)
          scp $PKG ${DEPLOY_HOST}:$STAGING_PATH
          echo "*** "$(date +"%H:%M:%S")" Generating .exe package signatures on staging"
          ssh ${DEPLOY_HOST} "cd $STAGING_PATH && md5sum $FILENAME > ${FILENAME}.md5 && sha256sum $FILENAME > ${FILENAME}.sha256"
        else
          echo "*** "$(date +"%H:%M:%S")" Building .exe package"
          mvn clean package -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION_OPTS
        fi
      '''
    }
  }
}
