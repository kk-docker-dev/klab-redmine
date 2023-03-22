#!/bin/bash

source /klab/scripts/utils.sh

# Trap SIGINT
trap 'echo -e "\nStopping Redmine ..."; exit 0' SIGINT

eval apache2ctl start

# Run infinitely
while true; do
	sleep 10
done

exit 0
