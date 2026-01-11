# build-srpm

This container builds RPM files from the Fedora source repository while removing
the OS-specific `filesystem` requirement.

This was developed specifically to allow the installation of more recent
versions of applications than what is included in RedHat Enterprise Linux (RHEL)
repositories without having to compile them on the host.

## Usage

```sh
podman run --rm -it \
--security-opt=label=disable \
--volume=$PWD:/output \
ghcr.io/doubleu-labs/build-srpm:latest \
[ packages ]
```
