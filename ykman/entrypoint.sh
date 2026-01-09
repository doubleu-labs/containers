#!/bin/bash

pcscd --debug --apdu --disable-polkit

"$@"
