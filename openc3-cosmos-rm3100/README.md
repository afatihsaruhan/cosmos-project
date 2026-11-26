# openc3-cosmos-rm3100

OpenC3 COSMOS plugin for the GZGN-EIU RM3100 magnetometer proof of concept
(NUCLEO-H723ZG). It defines the `RM3100` target and its interface.

```
board --USB--> bridges/rm3100-serial --TCP 2950--> RM3100_INT (this plugin) --> COSMOS tools
```

The interface does not open the serial port: COSMOS runs in Docker. It connects
to the RM3100 bridge (`../bridges/rm3100-serial`), which must be running.

## Contents

| Path | What |
| --- | --- |
| `plugin.txt` | Target and `RM3100_INT` interface (TCP client + `LENGTH` protocol) |
| `targets/RM3100/cmd_tlm/rm3100_cmd.txt` | Commands |
| `targets/RM3100/cmd_tlm/rm3100_tlm.txt` | Telemetry packets |
| `targets/RM3100/cmd_tlm/_ccsds_*_header.txt` | Shared CCSDS header, included with `render` |

Source of truth for the wire format is `firmware/apps/rm3100/rm3100_contract.json`
in the GZGN-EIU repository. This first version is written by hand and covers
only the first demo (issue #1 step 4):

- Commands: `CONTINUOUS_START` (0x208), `CONTINUOUS_STOP` (0x209)
- Telemetry: `MEASUREMENT` (0x110), `COMMAND_STATUS` (0x118)

Other telemetry APIDs reach COSMOS as `UNKNOWN` packets until they are defined.
X, Y and Z are converted to microtesla with the nominal cycle-count-200 gain
(75 counts/uT); the raw counts stay available as the RAW value.

## Wire format in short

Raw CCSDS space packets, big-endian, no CRC, no sync pattern:
6-byte primary header (version 0, type TM=0/TC=1, secondary header flag 1,
11-bit APID, sequence flags 3, 14-bit count, length = bytes after the primary
header - 1) and an 8-byte millisecond timestamp, then the payload.

## Build and install

From the cosmos-project folder (COSMOS running):

```bash
cd openc3-cosmos-rm3100
../openc3.sh cli rake build VERSION=0.1.0
../openc3.sh cli load openc3-cosmos-rm3100-0.1.0.gem
```

Or upload the `.gem` in the COSMOS Admin Console, Plugins tab. To change the
bridge port or host, edit the variables when installing.

## Check

1. Start the bridge (`../bridges/rm3100-serial/README.md`).
2. CmdTlmServer: `RM3100_INT` is CONNECTED and its RX bytes grow.
3. Packet Viewer, `RM3100 MEASUREMENT`: updates about 139 times per second.
4. Command Sender: `RM3100 CONTINUOUS_STOP` stops the measurements and
   `RM3100 COMMAND_STATUS` shows `LAST_TC_APID 0x209`, `ACK`;
   `CONTINUOUS_START` starts them again.
