Configuration :

pom.xml :

- Change the version of the `.zip` manually in the `pom.xml`, if suffixed with `SNAPSHOT`, file will be upload to `vendor-snapshots` nexus repository, otherwise, file will be uploaded to `vendor-releases` nexus repository

Deploy :

- `mvn deploy`

To add or remove Windows executable, simply edit the `zip.sh` script
