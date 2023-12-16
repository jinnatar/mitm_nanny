#!/bin/bash
set -u

## Nanny v2.0

# To install:
# - ./nanny.sh host1 host2 host3 ...
# - If you have a range of devices: ./nanny.sh atv0{1..99} atv{100..300}
# - Reboot devices to activate nanny.
# - Monitor /sdcard/nanny.log to see what's going on.

# You could customise these values ¯\_(ツ)_/¯
interval=10 # check every interval seconds
reporting=90 # interval x reporting = reporting interval
cooldown=60 # wait cooldown seconds for mitm before checking
log="/sdcard/nanny.log" # log for all output, cleared for every run of nanny.

targets=("$@")

for target in "${targets[@]}"; do
  adb connect "$target" 
  cat<<EOT | adb -s "$target" shell "su -c 'cat > /data/adb/service.d/nanny.sh && chmod +x /data/adb/service.d/nanny.sh'"

#!/system/bin/sh
# ^ says sh, but we assume it to be ash
# This script rendered at $(date -u +%Y-%m-%dT%T) for $target

# Wait a bit to work out Magisk kinks
while [ "\$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 1; done
sleep 10

touch "$log"

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

rotom="\$(grep rotom_url /data/local/tmp/config.json | cut -d \" -f 4)"
rotom_host="\$(echo \$rotom | cut -d / -f 3)"
rotom_proto="\$(echo \$rotom | cut -d : -f 1)"
rotom_ip=\$(nslookup "\$rotom_host" | tail -n 1 | cut -d ' ' -f 3)

rotom_port=80
[[ "\$rotom_proto" == "wss" ]] && rotom_port=433

echo "Nanny starting at \$(date +%Y-%m-%dT%T), expected rotom conn: \${rotom_ip}:\${rotom_port}"
echo "Checking every ${interval}s but reporting success only every ~$((interval * reporting))s."
echo "First check in ${cooldown}s to give the mitm a bit of space."
sleep "$cooldown"

checks=0
while true; do
	while [[ \$(pidof com.gocheats.launcher) ]]; do
		if [[ \$(ss -pnt | grep pokemongo | grep "\${rotom_ip}:\${rotom_port}" | wc -l) -lt 1 ]]; then
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
	am start com.gocheats.launcher/com.gocheats.launcher.MainActivity
	echo "PAUSE_CHECKS at \$(date +%Y-%m-%dT%T)"
	sleep "$cooldown"  # give mitm a bit of time to get up
	echo "RESUME_CHECKS at \$(date +%Y-%m-%dT%T)"
done
EOT

  done
echo "Reboot devices at your leisure to activate Nanny. Check $log to see what's going on."
