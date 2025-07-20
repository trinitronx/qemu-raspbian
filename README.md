<!-- markdownlint-configure-file
{
  "required-headings": {
    "headings": [
      "# QEMU Raspberry Pi Emulator",
      "*",
      "## Features",
      "*",
      "## Requirements",
      "*",
      "## Sponsor",
      "*",
      "## Setup",
      "*",
      "## Usage",
      "*",
      "## Default Credentials",
      "*",
      "## Networking",
      "*",
      "## File Structure",
      "*",
      "## Maintenance",
      "*",
      "## Notes",
      "*"
    ]
  }
}
-->
# QEMU Raspberry Pi Emulator

This project provides a `Makefile` and scripts to help boot Raspberry Pi OS
(Raspbian) in QEMU for both Raspberry Pi 3B and 4B models. It handles image
downloading, modification, and QEMU setup automatically.

## Features

- Downloads the Raspberry Pi OS Lite image
- Converts raw `.img` to compressed `.qcow2` format
- Resizes image to 4GiB
- Modifies the image to:
  - Disable USB OTG mode
  - Enable `dwc2` module
  - Set default `pi` user password to `raspberrypiqemu`
  - Enable SSH with `authorized_keys` copied from your user account
- Supports both Raspberry Pi 3B and 4B models
  - Patches Raspberry Pi 4 device tree to enable USB controller
  - No device tree changes needed for Raspberry Pi 3
- Includes networking configuration
  - Defaults to using `virbr0` from `libvirtd`
    (user should create & start this bridge network if not already created)
  - Option for localhost-only network with forwarded SSH port `5555`
    If using: uncomment in the `run-*.sh` script & comment the `virbr0`.

## Requirements

- QEMU
- `qemu-tools`
- `qemu-img`
- `nbd` kernel module
- `dtc` (device tree compiler)
- `wget`
- `unxz` / `xz`
- `bridge-utils` (for `libvirt` networking)

## Sponsor

If you find this project useful and appreciate my work,
would you be willing to click one of the buttons below to Sponsor this project
and help me continue?

<!-- markdownlint-disable MD033  -->
| Method       | Button                                                                                                                               |
| :----------- | :----------------------------------------------------------------------------------------------------------------------------------: |
| GitHub       | [![💖 Sponsor](https://trinitronx.github.io/assets/img/gh-button-medium.svg)](https://github.com/sponsors/trinitronx)                                                                                 |
| Liberapay    | [![Support with Liberapay](https://liberapay.com/assets/widgets/donate.svg)](https://liberapay.com/trinitronx/donate)                |
| PayPal       | [![Support with PayPal](https://trinitronx.github.io/assets/img/paypal-button-medium-blue.svg)](https://paypal.me/JamesCuzella)              |
| Ko-Fi        | [![Support with Ko-Fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/trinitronx)                                     |
| BuyMeACoffee | [![Buy Me a Coffee](https://trinitronx.github.io/assets/img/bmc-button-medium.svg)](https://www.buymeacoffee.com/TrinitronX) |
| Polar        | [![Support with Polar](https://trinitronx.github.io/assets/img/polar-button-medium-dark.svg)](https://polar.sh/lyraphase)                   |
| Patreon <sup>(_my artist page_)</sup> | [![Support with Patreon](https://img.shields.io/badge/dynamic/json?logo=patreon&style=for-the-badge&color=ffac00&label=Patreon&query=data.attributes.patron_count&suffix=%20patrons&url=https%3A%2F%2Fwww.patreon.com%2Fapi%2Fcampaigns%2F2379189)](https://www.patreon.com/bePatron?u=16585899)                                     |
<!-- markdownlint-enable MD033  -->

Every little bit is appreciated! Thank you! 🙏

## Setup

1. Clone this repository
2. Run the following command:

```shell
make prep-image
```

The Makefile will:

1. Download the Raspberry Pi OS image
2. Convert it to `qcow2` format
3. Ask for `sudo` password to mount the image with `qemu-nbd`
4. Resize and modify the image

## Usage

To run Raspberry Pi 3B:

```shell
make run-raspi3
```

To run Raspberry Pi 4B:

```shell
make run-raspi4
```

The prerequisites for each will be run by the `Makefile`:

1. Extract necessary boot files
2. Patch the Raspberry Pi 4 device tree (for `run-raspi4`)
   - Decompile `.dtb` into `.dts`
   - Patch the `.dts` to enable USB controller
   - Recompile `.dts.patched` into `.mod.dtb`
3. Boot the QEMU VM

## Default Credentials

- Username: `pi`
- Password: `raspberrypiqemu`

## Networking

The virtual machine is configured with:

- Bridged networking using `virbr0`
- SSH access (your public key is copied from `~/.ssh/authorized_keys`)

To SSH to the VM when in bridged networking mode, check the VM's IP address
visible in the `getty` login window.  Then run:

```shell
ssh -o UserKnownHostsFile=/dev/null pi@$IP_HERE
```

An example `libvirt` network XML for the `default` network is:

```xml
<network>
  <name>default</name>
  <uuid>906207b9-6fee-426d-8547-e97d3b37e0bb</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:aa:6b:40'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

Place the file contents in `default.xml` and run:

```shell
sudo virsh net-define  /tmp/default.xml
sudo virsh net-start default
```

To use local networking with only a forwarded port instead, comment out the
related `-netdev bridge` lines from the appropriate `run-raspi*.sh` script.  For
example:

```shell
# Bridged via libvirt virbr0 (must be created manually)
# -netdev bridge,id=net0,br=virbr0,helper=/usr/lib/qemu/qemu-bridge-helper
# -device usb-net,netdev=net0
```

Then, uncomment the lines:

```shell
# localhost forwarding
-device usb-net,netdev=net0
-netdev user,id=net0,hostfwd=tcp::5555-:22
```

You can then SSH to the VM with:

```shell
ssh -o UserKnownHostsFile=/dev/null -p 5555 pi@127.0.1.1
```

## File Structure

- `Makefile` - Main build and run script
- `run-raspi3.sh` - QEMU run script for Raspberry Pi 3B
- `run-raspi4.sh` - QEMU run script for Raspberry Pi 4B
- `get-rpi-img.sh` - Script to download Raspberry Pi OS image
- `mnt/` - Temporary mount points for image modification
- `*.dts`, `*.dtb` - Device tree files and patches

## Maintenance

To clean up:

```shell
make clean      # Remove generated QEMU boot files
make clean-all  # Remove all downloaded and generated files
```

QEMU boot files include:

- `kernel8.img`
- `bcm2710-rpi-3-b.dtb`
- `bcm2711-rpi-4-b.dtb`

## Notes

<!-- markdownlint-disable MD046 -->
- The Raspberry Pi 4 configuration includes a device tree patch that enables
  USB functionality
- Both configurations include USB keyboard and mouse support
- The image is pre-configured for headless operation with SSH enabled
- The default password is insecure, and can be changed at the top of the `Makefile`
  - Format is: `user:passwd-hash`
    - e.g. `pi:$6$6jHfJHU59JxxUfOS$k9natRNnu0AaeS/S9/IeVgSkwkYAjwJfGuYfnwsUoBxlNocOn.5yIdLRdSeHRiw8EWbbfwNSgx9/vUhu0NqF50`
  - Any '`$`' characters in the password hash must be escaped by doubling them: '`$$`'
    - For example, the above would become:

          pi:$$6$$6jHfJHU59JxxUfOS$$k9natRNnu0AaeS/S9/IeVgSkwkYAjwJfGuYfnwsUoBxlNocOn.5yIdLRdSeHRiw8EWbbfwNSgx9/vUhu0NqF50
<!-- markdownlint-enable MD046  -->
