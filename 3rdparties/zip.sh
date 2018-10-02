#!/bin/bash -xe
#
# (C) Copyright 2018 Nuxeo SA (http://nuxeo.com/) and others.
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
#

VERSION=${1:-1.0-SNAPSHOT}

rm -rf target/package
mkdir -p target/package
cd target

if [ ! -d ffmpeg ]; then
    git clone https://git.ffmpeg.org/ffmpeg.git
fi
cd ffmpeg
git checkout ae6f6d4e34b8353a547be48fbf34b95a1c3652e9
mkdir -p ../package/ffmpeg
git archive ae6f6d4e34 | tar -C ../package/ffmpeg -xf -
cd ..

if [ ! -d ImageMagick ]; then
    git clone https://github.com/ImageMagick/ImageMagick.git
fi
cd ImageMagick
git checkout b0c0d00dac949bffd6241905146ceb2b9a45314a
mkdir -p ../package/ImageMagick
git archive b0c0d00dac949bffd6241905146ceb2b9a45314a | tar -C ../package/ImageMagick -xf -
cd ..

### poppler 0.51 (pdftohtml)
wget -nc --no-check-certificate http://blog.alivate.com.au/wp-content/uploads/2017/01/poppler-0.51_x86.7z
unzip poppler-0.51_x86.7z
mv poppler-0.51 package/pdftohtml

### Ghostscript 9.22
wget -nc https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs922/gs922w32.exe -P package/gs

### exiftool
wget -nc https://sno.phy.queensu.ca/~phil/exiftool/exiftool-11.11.zip
unzip exiftool-11.11.zip -d package/exiftool

### Java 8 Openjdk
wget -nc https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.131-1/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64.zip
unzip java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64.zip -d package/java

zip -r windows3rdParties-${VERSION}.zip package/*

