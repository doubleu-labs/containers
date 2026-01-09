# YubiKey Manager (ykman)

This container provides the `yubikey-manager` CLI without having to install or
compile it.

There may still be some system preparations that you must do to comply with
system security policies.

## SELinux

If SELinux is installed and enforcing on the system intended to run this
container, a policy module will need to be installed to allow containers to
access USB devices.

Here is the policy in two different formats. Pick whichever you're more
comfortable installing.

### Common Intermediate Languate (cil)

```conf
# container_t_usb_device_t.cil
(typeattributeset cil_gen_require container_t)
(typeattributeset cil_gen_require usb_device_t)
(allow container_t usb_device_t (chr_file (getattr ioctl open read write)))
```

```sh
sudo semodule -i container_t_usb_device_t.cil
```

## Type Enforcement (te)

```conf
# container_t_usb_device_t.te
module container_t_usb_t 1.0;

require {
    type container_t;
    type usb_device_t;
    class chr_file { getattr ioctl open read write };
}

allow container_t usb_device_t:chr_file { getattr ioctl open read write };
```

```sh
checkmodule -M -m -o container_t_usb_device_t.mod container_t_usb_device_t.te
```

```sh
semodule_package -o container_t_usb_device_t.pp -m container_t_usb_device_t.mod
```

```sh
sudo semodule -i container_t_usb_device_t.pp
```

## Udev

While not strictly necessary, this `udev` rule creates a "well-known" symbolic
link to an inserted Yubikey at `/dev/yubikey`. If the serial number is set to be
visible over USB, then it will be appended (`/dev/yubikey0123456789`). This may
be useful if multiple YubiKeys are needed on the same system.

The `GROUP` assigned here should also be consistent with a group assigned to the
user running the container.

```conf
# /etc/udev/rules.d/99-yubikey.rules
SUBSYSTEM=="usb", \
ATTRS{idVendor}=="1050", \
ATTRS{idProduct}=="0401|0402|0403|0404|0405|0406|0407", \
SYMLINK+="yubikey$attr{serial}", \
GROUP="yubikey", \
TAG+="uaccess"
```

```sh
sudo udevadm control --reload && sudo udevadm trigger
```

## Polkit

Some distributions, such as Red Hat Enterprise Linux (RHEL), include default
`polkit` rules that deny non-root users access to the `pcscd` daemon.

```js
// /etc/polkit-1/rules.d/10-yubikey.rules
polkit.addRule(function(action, subject) {
  if (action.id == "org.debian.pcsc-lite.access_pcsc") {
    // Change USER to the user running the container
    if (subject.user == "USER") {
      return polkit.Result.YES;
    }
  }
  if (action.id == "org.debian.pcsc-lite.access_card") {
    // This allows the USER access to any connected YubiKey
    if (action.lookup("reader").startsWith("Yubico Yubikey")) {
        return polkit.Result.YES;
    }

    // If the YubiKey exposes the serial number over USB and you want to
    //  restrict the USER to a specific key, comment out the above, uncomment
    //  the below block, and replace SERIAL with the YubiKey's serial number.

    if (
        action.lookup("reader").startsWith("Yubico YubiKey") &&
        action.lookup("reader").includes("SERIAL")
    ) {
      return polkit.Result.YES;
    }
  }
});
```

```sh
sudo systemctl restart polkit.service
```

## Run

The YubiKey is accessed through `pcscd` using the user's `dbus` socket.

```sh
podman run --rm -it \
--volume /run/user/$(id -u)/bus:/run/user/9000/bus \
--device=/dev/yubikey* \
--group-add=keep-groups \
ghcr.io/doubleu-labs/ykman:latest \
ykman --help
```

## License

This container is licensed under [MIT](../LICENSE).

`yubikey-manager` itself is licensed under
[BSD-2-CLAUSE](https://github.com/Yubico/yubikey-manager/blob/main/COPYING).
