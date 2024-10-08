# dnsmasq

This container is [dnsmasq](https://dnsmasq.org/doc.html). The current version
is set at the head of [Containerfile](./Containerfile).

This container will require the `NET_ADMIN` and `NET_RAW` capabilities.

It is compiled with the `HAVE_BROKEN_RTC` flag because the intention is to run
this in an isolated Out-of-Band Management (OOBM) network where time
syncronization is not currently available in my environment.

The default command runs the application in the foreground and in debug mode, so
logs are printed to the container's `stdout`.

By default, dnsmasq will look for the configuration at `/etc/dnsmasq.conf`.

DNS (53TCP & 53UDP), DHCP (67UDP), and TFTP (69UDP) are exposed.
