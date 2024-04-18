# MitM Nanny

## Checks performed
- The MitM is checked to be running and to have at least one outbound connection to the upstream websocket.
- If those fail, the MitM is restarted.
- That's it, and that's all you really need.

<img align="right" src="logo512.png" alt="A logo of a pixel art nanny assisting an enthusiastic kitten." hspace="20"/>
<br/><br/><br/><br/><br/>

<!--ts-->
* [MitM Nanny](#mitm-nanny)
   * [Checks performed](#checks-performed)
   * [Installation:](#installation)
   * [Alternative low-tech installation:](#alternative-low-tech-installation)
   * [Upgrading](#upgrading)
   * [Stopping and removing Nanny](#stopping-and-removing-nanny)
   * [Known limitations](#known-limitations)
   * [Config](#config)
   * [Sample session log](#sample-session-log)
<!--te-->

## Installation:
- The script is intended to be installed from a Unix/Linux like environment and depends on having `bash` & `adb` available.
- All arguments to `nanny.sh` are interpreted as adb reachable addresses.
- `nanny.sh` handles the connection & installation for you and embeds the nanny script itself: `./nanny.sh host1 host2 host3 192.168.1.21`
- If you have a range of devices, you can use a bash/zsh range expansion: `./nanny.sh atv0{1..99}`
- Once pushed to devices, reboot them to activate nanny.
- Monitor `/sdcard/nanny.log` to see what's going on.

## Alternative low-tech installation:
If you don't want to customize anything and can't run `nanny.sh` due to not having a bash environment to run it in, you could use `manual_nanny.sh` instead. It's a pre-rendered default settings nanny script.
1. Edit `manual_nanny.sh` towards the top to set your MitM package name.
1. Somehow `adb push` the file onto a device. For example `adb push manual_nanny.sh /sdcard`
2. With root permissions, place it into `/data/adb/service.d/`. For example `su -c "mv /sdcard/manual_nanny.sh /data/adb/service.d/"`
3. Make sure the script is executable: `su -c "chmod +x /data/adb/service.d/manual_nanny.sh"`

## Upgrading
Just repeat the installation steps & reboot!

## Stopping and removing Nanny
1. Remove the script, for example `adb -s $host shell 'su -c "rm /data/adb/service.d/nanny.sh"'`
2. Reboot the device to stop the running copy, or see the top of `/sdcard/nanny.log` for the pid number and kill that one.

## Known limitations
- Action is taken by default only if there are zero upstream connections. This could be autodetected to control connection + worker connections, but doesn't seem to be necessary right now and could cause useless churn.


## Config
The script has a handful of variables set at the top you could customize, but the defaults work well.
- `interval=30` # check every interval seconds
- `reporting=30` # interval x reporting = reporting interval
- `initial_cooldown=30` # wait initial_cooldown seconds on boot before action
- `cooldown=240` # wait cooldown seconds for mitm before checking after an action
- `log="/sdcard/nanny.log"` # log for all output, cleared for every run of nanny.
- `connection_min=1` # Number of upsteam ws connections to require. Not all mitms will support a value over 1.
- `mitm="com.gocheats.launcher"` # package name of mitm. You can also set the env variable `NANNY_MITM` to override at runtime.


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
