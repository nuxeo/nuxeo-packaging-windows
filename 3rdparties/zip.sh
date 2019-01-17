#!/bin/bash -xe
#
# (C) Copyright 2018-2019 Nuxeo SA (http://nuxeo.com/) and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Contributors:
#     Alexis Timic
#     Julien Carsique
#     Frantz Fischer

VERSION=${1:-1.0-SNAPSHOT}

mkdir -p target/package
pushd target > /dev/null

# FFmpeg
FFMPEG_FILE=${FFMPEG_FILE:-ffmpeg-4.1-win32-static}
wget -nc -nv "https://ffmpeg.zeranoe.com/builds/win32/static/${FFMPEG_FILE}.zip"
unzip "${FFMPEG_FILE}.zip" -d package
mv "package/${FFMPEG_FILE}" package/ffmpeg

# ImageMagick
IMAGEMAGICK_VERSION=${IMAGEMAGICK_VERSION:-7.0.8-24-portable-Q16-x86}
wget -nc -nv "https://imagemagick.org/download/binaries/ImageMagick-${IMAGEMAGICK_VERSION}.zip"
# ignore error about backslashes, extraction is being performed anyway
unzip "ImageMagick-${IMAGEMAGICK_VERSION}.zip" -x www\* -d package/ImageMagick || true

# Poppler (pdftohtml)
POPPLER_VERSION=${POPPLER_VERSION:-0.68.0}
POPPLER_RELEASE_DATE=${POPPLER_RELEASE_DATE:-2018\/10}
wget -nc -nv --no-check-certificate "http://blog.alivate.com.au/wp-content/uploads/${POPPLER_RELEASE_DATE}/poppler-${POPPLER_VERSION}_x86.7z"
7z e "poppler-${POPPLER_VERSION}_x86.7z" -xr\!share\* -xr\!include\* -xr\!pkgconfig\* -opackage/pdftohtml
rmdir package/pdftohtml/bin package/pdftohtml/lib "package/pdftohtml/poppler-${POPPLER_VERSION}"

# Ghostscript (32 and 64 bits versions)
GHOSTSCRIPT_VERSION=${GHOSTSCRIPT_VERSION:-926}
wget -nc -nv "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${GHOSTSCRIPT_VERSION}/gs${GHOSTSCRIPT_VERSION}w32.exe"
wget -nc -nv "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${GHOSTSCRIPT_VERSION}/gs${GHOSTSCRIPT_VERSION}w64.exe"
7z x "gs${GHOSTSCRIPT_VERSION}w32.exe" -y -xr\!Resource\* -xr\!examples\* -opackage/gs
7z x "gs${GHOSTSCRIPT_VERSION}w64.exe" -y -xr\!Resource\* -xr\!examples\* -opackage/gs
# removed unneeded files that could not be excluded from extraction
rm -rf package/gs/\$PLUGINSDIR

# exiftool
EXIFTOOL_FILE=${EXIFTOOL_FILE:-exiftool-11.11}
wget -nc -nv "https://www.sno.phy.queensu.ca/~phil/exiftool/${EXIFTOOL_FILE}.zip"
mkdir -p package/misc/bin
unzip "${EXIFTOOL_FILE}.zip" -d package
mv "package/exiftool(-k).exe" package/misc/bin/exiftool.exe

# Java 8
JAVA_VERSION=${JAVA_VERSION:-1.8.0}
JAVA_REVISION=${JAVA_REVISION:-191-1}
JAVA_BUILD=${JAVA_BUILD:-12}
JAVA_FILE=${JAVA_FILE:-java-1.8.0-openjdk-${JAVA_VERSION}.${JAVA_REVISION}.b${JAVA_BUILD}.ojdkbuild.windows.x86}
wget -nc -nv "https://github.com/ojdkbuild/ojdkbuild/releases/download/${JAVA_VERSION}.${JAVA_REVISION}/${JAVA_FILE}.zip"
unzip "${JAVA_FILE}".zip -d package
mv package/"${JAVA_FILE}" package/java

pushd package > /dev/null
zip -r "../windows3rdParties-${VERSION}.zip" ./*
popd > /dev/null

popd > /dev/null
