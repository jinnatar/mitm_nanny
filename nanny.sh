#!/bin/bash
set -u

nanny_version="2.5"

# To install:
# - ./nanny.sh host1 host2 host3 ...
# - If you have a range of devices: ./nanny.sh atv0{1..99} atv{100..300}
# - Reboot devices to activate nanny.
# - Monitor /sdcard/nanny.log to see what's going on.

# You could customise these values ¯\_(ツ)_/¯
interval=30 # check every interval seconds
reporting=30 # interval x reporting = reporting interval
initial_cooldown=30 # wait initial_cooldown seconds on boot before action
cooldown=240 # wait cooldown seconds for mitm before checking after an action
log="/sdcard/nanny.log" # log for all output, cleared for every run of nanny.
connection_min=1 # Number of upsteam ws connections to require. Not all mitms will support a value over 1.
mitm="com.gocheats.launcher" # package name of mitm. You can also set the env variable NANNY_MITM to override at runtime.

# Nothing to configure below here
targets=("$@")
mitm="${NANNY_MITM:-$mitm}"

for target in "${targets[@]}"; do
  adb connect "$target" 
  cat<<EOT | adb -s "$target" shell "su -c 'cat > /data/adb/service.d/nanny.sh && chmod +x /data/adb/service.d/nanny.sh'"
#!/system/bin/sh
# ^ says sh, but we assume it to be ash
# This script (nanny v${nanny_version}) was rendered at $(date -u +%Y-%m-%dT%T) for $target

mitm="$mitm"
mitm_slug="\${mitm: -10}"

# Wait a bit to work out Magisk kinks, but only on initial bootstrap run
if [[ "\$1" != "nanny" ]]; then
	while [ "\$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 1; done
	sleep 10
	touch "$log"
fi

# we need root
if [[ "\$(whoami)" != "root" ]]; then
	echo "\$(date +%Y-%m-%dT%T) - Not running as root, cannot nanny." | tee "$log"
	exit 1
fi

# re-exec for logging
if [[ "\$1" != "nanny" ]]; then
	echo "\$0: Enabling logging to $log" | tee "$log"  # clear and start new log
        exec "\$0" nanny | tee -a "$log"
        exit \$?
fi

# Adjust OOM score to hopefully not get randomly killed
echo -1000 > /proc/self/oom_score_adj

# Load upstream endpoint data from mitm config
if [[ -f /data/local/tmp/cosmog.json ]]; then
	rotom="\$(grep rotom_worker_endpoint /data/local/tmp/cosmog.json | cut -d \" -f 4)"
elif [[ -f /data/local/tmp/config.json ]]; then
	rotom="\$(grep rotom_url /data/local/tmp/config.json | cut -d \" -f 4)"
else
	echo "\$(date +%Y-%m-%dT%T) - No mitm config found on device, cannot nanny upstream connections."
	exit 1
fi

# Split upstream to port, proto & host and turn host into an ip address
rotom_host="\$(echo \$rotom | cut -d / -f 3 | cut -d : -f 1)"
rotom_port="\$(echo \$rotom | cut -d / -f 3 | cut -sd : -f 2)"  # if there is a manual port
rotom_proto="\$(echo \$rotom | cut -d : -f 1)"
# Dirty hack to resolve a host where no dns tools are available.
rotom_ip="\$(ping -c 1 "\$rotom_host" | grep PING | cut -d \( -f 2 | cut -d \) -f 1)"

if [ -z "\$rotom_port" ]; then  # no manual port defined, assume websocket defaults
	rotom_port=80
elif [[ "\$rotom_proto" == "wss" ]]; then
	rotom_port=433
fi

echo "Nanny starting at \$(date +%Y-%m-%dT%T), pid: \$\$, expected rotom conn: \${rotom_ip}:\${rotom_port} from either pogo or \$mitm_slug"
echo "Checking every ${interval}s but reporting success only every ~$((interval * reporting))s."
echo "First check in ${cooldown}s to give the mitm a bit of space."
sleep "$initial_cooldown"

checks=0
while true; do
	while [[ \$(pidof "\$mitm") ]]; do
		if [[ \$(ss -pnt | grep -E "\$mitm_slug|pokemongo" | grep -E "\${rotom_ip}(]){0,1}:\${rotom_port}" | wc -l) -lt "$connection_min" ]]; then
			echo "DISCONNECT at \$(date +%Y-%m-%dT%T)"
			break
		fi

		# By default every 90 checks i.e. 15 minutes
		[[ \$((checks % $reporting)) -eq 0 ]] && echo "FINE at \$(date +%Y-%m-%dT%T) (check #\${checks})"
		let checks++
		sleep $interval
	done
	echo "TAKING_ACTION at \$(date +%Y-%m-%dT%T) (check #\${checks})"
	checks=0  # reset counter
	am force-stop com.nianticlabs.pokemongo
	monkey -p "\$mitm" 1
	echo "PAUSE_CHECKS at \$(date +%Y-%m-%dT%T)"
	sleep "$cooldown"  # give mitm a bit of time to get up
	echo "RESUME_CHECKS at \$(date +%Y-%m-%dT%T)"
done
EOT

  done
>&2 echo "Reboot devices at your leisure to activate Nanny. Check $log to see what's going on."
