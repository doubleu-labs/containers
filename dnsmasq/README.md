# dnsmasq

This container is [dnsmasq](https://dnsmasq.org/doc.html). The current version
is set at the head of the [Containerfile](./Containerfile).

This container requires the `NET_ADMIN` and `NET_RAW` capabilities.

The default command runs the application in the foreground and in debug mode, so
logs are printed to the container's `stdout`.

By default, `dnsmasq` will look for the configuration at `/etc/dnsmasq.conf`.

DNS (53/TCP & 53/UDP), DHCP (67/UDP), and TFTP (69/UDP) are exposed.

This container comes in two variants: `dnsmasq` and `dnsmasq-nortc`. The former
is the default build, while the later was compiled with the `HAVE_BROKEN_RTC`
option. This is useful when used on a device that does not have an RTC, or where
network time syncronization is not available.
