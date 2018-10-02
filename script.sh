#!/bin/bash -xe

if [ ! -d windows ]; then
    mkdir windows
fi
cd windows

if [ ! -d package ]; then
    mkdir package
fi
cd package

if [ ! -d ffmpeg ]; then
    git clone https://git.ffmpeg.org/ffmpeg.git
fi
cd ffmpeg
git checkout ae6f6d4e34b8353a547be48fbf34b95a1c3652e9
cd ..

if [ ! -d ImageMagick ]; then
    git clone https://github.com/ImageMagick/ImageMagick.git
fi
cd ImageMagick
git checkout b0c0d00dac949bffd6241905146ceb2b9a45314a
cd ..

cd ..

### poppler 0.51 (pdftohtml)
wget -nc --no-check-certificate --show-progress http://blog.alivate.com.au/wp-content/uploads/2017/01/poppler-0.51_x86.7z
mkdir tmp
for f in poppler-0.51_x86.7z; do unzip -ou "$f" -d tmp/ && mv -n tmp/* "package/pdftohtml"; done
rm -r tmp

### Ghostscript 9.22
wget -nc --show-progress https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs922/gs922w32.exe -P package/gs

### exiftool
wget -nc --show-progress https://sno.phy.queensu.ca/~phil/exiftool/exiftool-11.11.zip
unzip -ou exiftool-11.11.zip -d "package/exiftool"

### Java 8 Openjdk
wget -nc --show-progress https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.131-1/java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64.zip
mkdir tmp
for f in java-1.8.0-openjdk-1.8.0.131-1.b11.ojdkbuild.windows.x86_64.zip; do unzip -ou "$f" -d tmp/ && mv -n tmp/* "package/java"; done
rm -r tmp

zip -r windows3rdParties-${1}.zip package/*
