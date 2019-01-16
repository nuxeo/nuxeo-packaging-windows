# Description

Third party tools bundled in the Windows installer.

# Usage

Manually update the artifact version in the `pom.xml`.

TODO: there is not yet continuous integration, it was not used to change.

It is manually released as a thirdparty (vendor) package.

# Verify
When upgrading versions, run `mvn verify` to double-check there is no side effect in the packaging.

- `mvn verify`

# Deploy

- `mvn deploy`

To add or remove Windows executable, simply edit the `zip.sh` script

# Dependencies
7zip, Unzip, Zip, wget, shunit2