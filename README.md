# MitM Nanny

## Checks performed
- The MitM is checked to be running.
- The MitM is checked to have at least one outbound connection to the upstream websocket.

## Installation:
- The script is intended to be installed from a Unix/Linux like environment and depends on having `bash` & `adb` available.
- All arguments to `nanny.sh` are interpreted as adb reachable addresses.
- `nanny.sh` handles the connection & installation for you and embeds the nanny script itself: `./nanny.sh host1 host2 host3 192.168.1.21`
- If you have a range of devices, you can use a bash/zsh range expansion: `./nanny.sh atv0{1..99}`
- Once pushed to devices, reboot them to activate nanny.
- Monitor `/sdcard/nanny.log` to see what's going on.

## Known limitations
- Action is taken by default only if there are zero upstream connections. This could be autodetected to control connection + worker connections, but doesn't seem to be necessary right now and could cause useless churn.

## Config
The script has a handful of variables set at the top you could customize, but the defaults work well.
- `interval=10` # check every interval seconds
- `reporting=90` # interval x reporting = reporting interval
- `cooldown=60` # wait cooldown seconds for mitm before checking
- `log="/sdcard/nanny.log"` # log for all output, cleared for every run of nanny.
- `connection_min=1` # Number of upsteam ws connections to require. Could optimise to 1+workers.
- `mitm="com.gocheats.launcher"` # package name of mitm

## Sample session log
```
/data/adb/service.d/nanny.sh: Enabling logging to /sdcard/nanny.log
Nanny starting at 2023-12-16T18:49:23, expected rotom conn: 192.186.1.10:80
Checking every 10s but reporting success only every ~900s.
First check in 60s to give the mitm a bit of space.
FINE at 2023-12-16T18:50:24 (check #0)
FINE at 2023-12-16T19:06:02 (check #90)
FINE at 2023-12-16T19:21:38 (check #180)
FINE at 2023-12-16T19:37:13 (check #270)
*snip*
FINE at 2023-12-17T02:06:14 (check #2520)
DISCONNECT at 2023-12-17T02:18:31
TAKING_ACTION at 2023-12-17T02:18:31 (check #2591)
  bash arg: -p
  bash arg: com.gocheats.launcher
  bash arg: 1
Events injected: 1
## Network stats: elapsed time=65ms (0ms mobile, 0ms wifi, 65ms not connected)
PAUSE_CHECKS at 2023-12-17T02:18:33
RESUME_CHECKS at 2023-12-17T02:19:33
FINE at 2023-12-17T02:19:34 (check #0)
FINE at 2023-12-17T02:35:07 (check #90)
FINE at 2023-12-17T02:50:41 (check #180)
```
