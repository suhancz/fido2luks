#!/bin/bash

check () {
}

depends () {
        return 0
}

install () {
        inst_simple "/usr/bin/fido2luks" "/usr/bin/fido2luks"
        inst_simple "/etc/fido2luks.conf" "/etc/fido2luks.conf"
        inst_simple "/usr/lib/dracut/96luks-2fa/keyscript.sh" "/usr/lib/dracut/96luks-2fa/keyscript.sh"
        mkdir -p "$initdir/luks-2fa"
}
