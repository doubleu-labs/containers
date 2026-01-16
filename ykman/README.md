
# YubiKey Manager (ykman)

This container provides the `yubikey-manager` CLI tool so you don't have to
compile or install it on your host system.

This requires you to pass only the PC/SC socket to the container. Doing it this
way prevents you from having to disable PC/SC on the host or applying the
`PCSCLITE_IGNORE` label on the device, allowing the YubiKey to be used in
multiple applications/containers.

This also prevents having to run PC/SC in the container itself, which could
result in API errors. This *should* be mitigated since this container is built
with PC/SC Lite `>=2.4.1`, which added API backward compatibility.

## Usage

```sh
IMAGE=ghcr.io/doubleu-labs/ykman:latest
# OR
IMAGE=quay.io/doubleu-labs/ykman:latest
```

```sh
podman run --rm -it -v /run/pcsc:/run/pcsc --security-opt=label=disable $IMAGE
```

## Additional Configuration

If you have PolKit enforcing, then you may need to configure a couple more
things.

Don't just blindly add this. Make sure you're actually receiveing denials before
intalling this since it modifies your system's security posture.

### PolKit

Some distributions, such as RedHat Enterprise Linux (RHEL), include default
`polkit` rules that deny all non-root users access to the `pcscd` daemon.

Instead of globally allowing access, create a system group and add users to that
to control access.

```sh
groupadd --system yubikey
```

```sh
usermod -aG yubikey $USER
```

```js
// /etc/polkit-1/rules.d/10-yubikey.rules
polkit.addRule(function(action, subject) {
  if (action.id == "org.debian.pcsc-lite.access_pcsc") {
    if (subject.isInGroup("yubikey")) {
      return polkit.Result.YES;
    }
  }
  if (action.id == "org.debian.pcsc-lite.access_card") {
    if (action.lookup("reader").startsWith("Yubico YubiKey")) {
        return polkit.Result.YES;
    }
  }
});
```

The above rule allows anyone on the `yubikey` group to access YubiKey devices
through the PC/SC daemon.

Restart PolKit to apply:

```sh
sudo systemctl restart polkit.service
```

Now, add some additional arguments to the `podman run` command:

```diff
  podman run --rm -it \
  -v /run/pcsc:/run/pcsc \
  --security-opt=label=disable \
+ --group-add=$(getent group yubikey | cut -d':' -f3) \
+ --userns=keep-id \
  $IMAGE
```

With some additional preparation, you could even further restrict this. In the
container, note the YubiKey's serial number:

```sh
ykamn list
```

```raw
YubiKey 5 NFC (5.4.3) [OTP+FIDO+CCID] Serial: 12345678
```

Then modify the `/etc/polkit-1/rules.d/10-yubikey.rules` policy. Ensure that the
serial number is 10-digits long. Left-pad with zeros as needed.

```diff
  // /etc/polkit-1/rules.d/10-yubikey.rules
  polkit.addRule(function(action, subject) {
    if (action.id == "org.debian.pcsc-lite.access_pcsc") {
      if (subject.isInGroup("yubikey")) {
        return polkit.Result.YES;
      }
    }
    if (action.id == "org.debian.pcsc-lite.access_card") {
-     if (action.lookup("reader").startsWith("Yubico YubiKey")) {
+     if (action.lookup("reader").startsWith("Yubico YubiKey") &&
+         action.lookup("reader").includes("0012345678")) {
          return polkit.Result.YES;
      }
    }
  });
```

Again, restart the PolKit service:

```sh
sudo systemctl restart polkit.service
```

## License

This container is licensed under [MIT](../LICENSE).

`yubikey-manager` itself is licensed under
[BSD-2-CLAUSE](https://github.com/Yubico/yubikey-manager/blob/main/COPYING).
