#!/bin/bash

oneTimeSetUp() {
    pushd target > /dev/null || fail
    echo "Uncompressing archive..."
    unzip -q windows3rdParties-*.zip -d testing
    popd > /dev/null || fail
}

oneTimeTearDown() {
    rm -rf target/testing
}

setUp() {
    pushd target/testing > /dev/null || fail
}

tearDown() {
  popd > /dev/null || fail
}

testFFmpegIsCorrectlyDeployed() {
  assertTrue 'FFmpeg is not found' '[ -f "ffmpeg/bin/ffmpeg.exe" ]'
}

testImageMagickIsCorrectlyDeployed() {
  assertTrue 'Convert is not found' '[ -f "ImageMagick/convert.exe" ]'
  assertTrue 'Identify is not found' '[ -f "ImageMagick/identify.exe" ]'
  assertFalse 'www folder should not be present' '[ -d "ImageMagick/www" ]'
}

testPdfToHtmlIsCorrectlyDeployed() {
  assertTrue 'PdfToHtml is not found' '[ -f "pdftohtml/pdftohtml.exe" ]'
  assertFalse 'include folder should not be present' '[ -d "pdftohtml/include" ]'
  assertFalse 'share folder should not be present' '[ -d "pdftohtml/share" ]'
  assertFalse 'pkgconfig folder should not be present' '[ -d "pdftohtml/pkgconfig" ]'
}

testGhostScriptIsCorrectlyDeployed() {
  assertTrue 'GhostScript is not found' '[ -f "gs/bin/gswin32.exe" ]'
  # shellcheck disable=SC2016
  assertFalse 'include folder should not be present' '[ -d "gs/\$PLUGINSDIR" ]'
  assertFalse 'share folder should not be present' '[ -d "gs/examples" ]'
  assertFalse 'pkgconfig folder should not be present' '[ -d "gs/Resource" ]'
}

testExifToolIsCorrectlyDeployed() {
    assertTrue 'ExifTool is not found' '[ -f "misc/bin/exiftool.exe" ]'
}

testJavaIsCorrectlyDeployed() {
    assertTrue 'Java is not found' '[ -f "java/bin/java.exe" ]'
}
