#!/bin/bash

set -euo pipefail

dnf download --source --destdir=/root "$@"
dnf builddep -y /root/*.src.rpm
rpm -ivh /root/*.src.rpm

for spec in /root/rpmbuild/SPECS/*.spec; do
    rpmbuild -bb "$spec" --define='__requires_exclude ^filesystem.*$'
done

cp $(ls -d /root/rpmbuild/RPMS/*/*.rpm | grep -v debug) /output
