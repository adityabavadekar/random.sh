#!/usr/bin/env bash

# Ctrl+Win+[ Stops

echo "[ LOCKDOWN ] starting system input lockdown"
echo "ALERT LOCK ON" | espeak-ng

cd ~/random.sh/input-locker
source .venv/bin/activate
python input_lock.py >~/input_lock.log 2>&1

echo "[ LOCKDOWN ] input restored"
