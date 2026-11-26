# RM3100 serial bridge

Carries the bytes of the NUCLEO-H723ZG + RM3100 board into COSMOS.

> **Temporary link.** This is the proof-of-concept USB connection: the board's
> UART reaches the PC through the onboard ST-LINK virtual COM port (USB, CN1).
> The flight link is **CAN with CSP** (GZGN-EIU issue #2). When it arrives only
> this bridge is replaced; COSMOS keeps connecting to the same TCP port and the
> RM3100 plugin, its commands and telemetry stay the same.

```
board --USB (ST-LINK VCP)--> [this bridge on the host] --TCP 2950--> COSMOS (Docker)
                              serial_interface + tcpip_server         RM3100 plugin
```

COSMOS runs in Docker and cannot open the USB serial port itself. This is
OpenC3's standard *bridge* (COSMOS docs, Guides > Bridges): it only passes bytes
through (`BURST`). Packet framing is done in COSMOS by the RM3100 plugin.

## What you need

- The board on CN1; its VCP appears as
  `/dev/serial/by-id/usb-STMicroelectronics_STLINK-V3_<probe-serial>-if02`.
  Your user needs access to it (ST-LINK udev rules from STM32CubeProgrammer,
  `Drivers/rules`, or membership of `dialout`).
- Python 3.10 or newer with `venv`.
- No other program holding the port (close `stmrm3100`, `stmtestmonitor`, CubeIDE
  serial consoles).

## Setup (once)

```bash
cd bridges/rm3100-serial
python3 -m venv .venv
.venv/bin/pip install openc3==7.5.1     # same version as COSMOS
```

Check two values in `bridge.txt`:

| Variable | Default | Change when |
| --- | --- | --- |
| `serial_port` | the lab board's by-id path | your board has another probe serial: `ls /dev/serial/by-id/` |
| `router_listen_address` | `172.17.0.1` | your docker0 address differs: `ip -4 addr show docker0` |

## Run

```bash
cd bridges/rm3100-serial
.venv/bin/openc3pycli bridge bridge.txt
```

Stop with Ctrl+C. Variables can be overridden without editing the file:

```bash
.venv/bin/openc3pycli bridge bridge.txt serial_port=/dev/ttyACM0
```

Until COSMOS connects, the log repeats `Error routing telemetry ... not
connected`; that is expected. `RM3100_SERIAL_ROUTER Connection Success` means
COSMOS is connected.

## Unplug and replug

The bridge reconnects to the serial port by itself (OpenC3 interfaces retry
every 5 s). Use the by-id path, not `/dev/ttyACM0`, so the port is found again
even if Linux renumbers it. While the board is unplugged the COSMOS interface
stays connected to the bridge but telemetry stops (packets turn stale).

## Optional: start with the computer (systemd user service)

Not installed by default. To run the bridge automatically, create
`~/.config/systemd/user/rm3100-bridge.service` (adjust the path):

```ini
[Unit]
Description=RM3100 serial bridge for OpenC3 COSMOS

[Service]
WorkingDirectory=%h/openc3/cosmos-project/bridges/rm3100-serial
ExecStart=%h/openc3/cosmos-project/bridges/rm3100-serial/.venv/bin/openc3pycli bridge bridge.txt
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rm3100-bridge     # start now and at login
journalctl --user -u rm3100-bridge -f           # follow the log
systemctl --user disable --now rm3100-bridge    # remove again
```

The service holds the serial port: stop it before using `stmrm3100` or
flashing tools that open the VCP.
