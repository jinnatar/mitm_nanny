# MitM Nanny

## Installation:

- All arguments to `nanny.sh` are interpreted as adb reachable addresses.
- `nanny.sh` handles the connection & installation for you and embeds the nanny script itself: `./nanny.sh host1 host2 host3 192.168.1.21`
- If you have a range of devices, you can use a bash/zsh range expansion: ./nanny.sh atv0{1..99}
- Once pushed to devices, reboot them to activate nanny.
- Monitor `/sdcard/nanny.log` to see what's going on.

## Known limitations
- Upstream connections are assumed to use standard ports, usually via a proxy, i.e. 80 for `ws` and 443 for `wss`.

## Config
The script has a handful of variables set at the top you could customize, but the defaults work well.
- `interval=10` # check every interval seconds
- `reporting=90` # interval x reporting = reporting interval
- `cooldown=60` # wait cooldown seconds for mitm before checking
- `log="/sdcard/nanny.log"` # log for all output, cleared for every run of nanny.

## Checks performed
- The MitM is checked to be running.
- The MitM is checked to have at least one outbound connection to the upstream websocket.
