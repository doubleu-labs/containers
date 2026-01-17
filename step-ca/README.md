# Smallstep CA

This container provides the Smallstep CA server and associated CLI tools.

`DOCKER_STEPCA_INIT_*` environment variables from the official image are
compatible.

## Versions

This container comes in two flavors:

### `step-ca`

This container contains the standard Smallstep CA, bundled with the `step` CLI
tool.

### `step-ca-hsm`

This container contains the Smallstep CA compiled with PC/SC Lite, the `step`
CLI tool, and the `step-kms-plugin` CLI plugin that allows management of KMS
devices and services.

To use a smartcard device attached to the host, be sure to pass `/run/pcscd` to
the container and disable labeling.

```sh
. . . --volume=/run/pcscd:/run/pcscd --security-opt=label=disable . . .
```
