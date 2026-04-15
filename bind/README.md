# Bind

This container provides the ISC Bind DNS Server.

## Usage

```sh
podman pull ghcr.io/doubleu-labs/bind:latest
```

or

```sh
podman pull quay.io/doubleu-labs/bind:latest
```

- `/etc/bind` - Configuration directory (`named.conf` should be here)
- `/var/cache/bind` - Working directory
- `/var/lib/bind` - Canonical location for secondary zones
- `/var/log` - Log files

```sh
podman run \
--name bind \
--restart always \
--publish 53:53/tcp \
--publish 53:53/udp \
--publish 443:443/tcp \
--publish 853:853/tcp \
--volume /etc/bind \
--volume /var/cache/bind \
--volume /var/lib/bind \
--volume /var/log \
ghcr.io/doubleu-labs/bind:latest
```
