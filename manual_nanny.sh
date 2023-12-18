#!/system/bin/sh
# ^ says sh, but we assume it to be ash
# This script (nanny v2.2) was rendered at 2023-12-18T18:40:09 for manual_nanny

# Wait a bit to work out Magisk kinks
while [ "$(getprop sys.boot_completed | tr -d '\r')" != "1" ]; do sleep 1; done
sleep 10

touch "/sdcard/nanny.log"

# we need root
if [[ "$(whoami)" != "root" ]]; then
	echo "$(date +%Y-%m-%dT%T) - Not running as root, cannot nanny." | tee "/sdcard/nanny.log"
	exit 1
fi

# re-exec for logging
if [[ "$1" != "nanny" ]]; then
	echo "$0: Enabling logging to /sdcard/nanny.log" | tee "/sdcard/nanny.log"  # clear and start new log
        exec "$0" nanny | tee -a "/sdcard/nanny.log"
        exit $?
fi

rotom="$(grep rotom_url /data/local/tmp/config.json | cut -d \" -f 4)"
rotom_host="$(echo $rotom | cut -d / -f 3 | cut -d : -f 1)"
rotom_port="$(echo $rotom | cut -d / -f 3 | cut -sd : -f 2)"  # if there is a manual port
rotom_proto="$(echo $rotom | cut -d : -f 1)"
# Dirty hack to resolve a host where no dns tools are available.
rotom_ip="$(ping -c 1 "$rotom_host" | grep PING | cut -d \( -f 2 | cut -d \) -f 1)"

if [ -z "$rotom_port" ]; then  # no manual port defined
	rotom_port=80
elif [[ "$rotom_proto" == "wss" ]]; then
	rotom_port=433
fi

echo "Nanny starting at $(date +%Y-%m-%dT%T), expected rotom conn: ${rotom_ip}:${rotom_port}"
echo "Checking every 10s but reporting success only every ~900s."
echo "First check in 60s to give the mitm a bit of space."
sleep "60"

checks=0
while true; do
	while [[ $(pidof "com.gocheats.launcher") ]]; do
		if [[ $(ss -pnt | grep pokemongo | grep "${rotom_ip}:${rotom_port}" | wc -l) -lt "1" ]]; then
			echo "DISCONNECT at $(date +%Y-%m-%dT%T)"
			break
		fi

		# By default every 90 checks i.e. 15 minutes
		[[ $((checks % 90)) -eq 0 ]] && echo "FINE at $(date +%Y-%m-%dT%T) (check #${checks})"
		let checks++
		sleep 10
	done
	echo "TAKING_ACTION at $(date +%Y-%m-%dT%T) (check #${checks})"
	checks=0  # reset counter
	am force-stop com.nianticlabs.pokemongo
	monkey -p "com.gocheats.launcher" 1
	echo "PAUSE_CHECKS at $(date +%Y-%m-%dT%T)"
	sleep "60"  # give mitm a bit of time to get up
	echo "RESUME_CHECKS at $(date +%Y-%m-%dT%T)"
done
