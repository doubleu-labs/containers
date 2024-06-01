#!/bin/sh
set -e

if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
    set -- valkey-server "$@"
fi

um=$(umask)
if [ "$um" = '0022' ]; then
    umask 0077
fi

exec "$@"
