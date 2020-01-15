# fido2luks [![Crates.io Version](https://img.shields.io/crates/v/fido2luks.svg)](https://crates.io/crates/fido2luks)

This will allow you to unlock your luks encrypted disk with an fido2 compatible key

Note: This has only been tested under Fedora 31 using a Solo Key, Trezor Model T

## Setup

### Prerequisites

```
dnf install cargo cryptsetup-devel -y
```

### Device

```
git clone https://github.com/shimunn/fido2luks.git && cd fido2luks

# Alternativly cargo build --release && sudo cp target/release/fido2luks /usr/bin/
sudo -E cargo install -f --path . --root /usr

# Copy template
cp dracut/96luks-2fa/fido2luks.conf /etc/
# Name is optional but useful if your authenticator has a display
echo FIDO2LUKS_CREDENTIAL_ID=$(fido2luks credential [NAME]) >> /etc/fido2luks.conf

# Load config into env
set -a
. /etc/fido2luks.conf

# Repeat for each luks volume
sudo -E fido2luks -i add-key /dev/disk/by-uuid/<DISK_UUID>

# Test(only works if the luks container isn't active)
sudo -E fido2luks -i open /dev/disk/by-uuid/<DISK_UUID> luks-<DISK_UUID>

```

### Dracut

```
cd dracut

sudo make install
```

### Grub

Add `rd.luks.2fa=<CREDENTIAL_ID>:<DISK_UUID>` to `GRUB_CMDLINE_LINUX` in /etc/default/grub

Note: This is only required for your root disk, systemd will try to unlock all other LUKS partions using the same key if you added it using `fido2luks add-key`

```
grub2-mkconfig > /boot/grub2/grub.cfg
```

I'd also recommend to copy the executable onto /boot so that it is accessible in case you have to access your disk from a rescue system

```
mkdir /boot/fido2luks/
cp /usr/bin/fido2luks /boot/fido2luks/
cp /etc/fido2luks.conf /boot/fido2luks/
```

## Test

Just reboot and see if it works, if that's the case you should remove your old less secure password from your LUKS header:

```
# Recommend in case you lose your authenticator, store this backupfile somewhere safe
cryptsetup luksHeaderBackup /dev/disk/by-uuid/<DISK_UUID> --header-backup-file luks_backup_<DISK_UUID>
# There is no turning back if you mess this up, make sure you made a backup
fido2luks -i add-key --exclusive /dev/disk/by-uuid/<DISK_UUID>
```

## Addtional settings

### Password less

Remove your previous secret as described in the next section, in case you've already added one.

Open `/etc/fido2luks.conf` and replace `FIDO2LUKS_SALT=Ask` with `FIDO2LUKS_SALT=string:<YOUR_RANDOM_STRING>`
but be warned that this password will be included to into your initramfs.

Import the new config into env:

```
set -a
. /etc/fido2luks.conf
```

Then add the new secret to each device and update dracut afterwards `dracut -f`

## Removal

Remove `rd.luks.2fa` from `GRUB_CMDLINE_LINUX` in /etc/default/grub

```
set -a
. fido2luks.conf
sudo -E fido2luks -i replace-key /dev/disk/by-uuid/<DISK_UUID>

sudo rm -rf /usr/lib/dracut/modules.d/96luks-2fa /etc/dracut.conf.d/luks-2fa.conf /etc/fido2luks.conf
```
