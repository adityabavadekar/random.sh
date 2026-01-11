#!/bin/bash

# STEPS
# 1. Activate Dev Mode on Target device
# 2. Find IP of it
# 3. Connect to PC
# 4. adb devices
# 5. adb tcpip 5555
# 6. adb connect IP_ADDR:5555
# 7. adb devices
# 8. Disconnect phone
# 9. scrcpy
# 10. DONE!!!

# Function to prompt user
prompt_user() {
  read -p "$1 [Y/N] (default: Y): " choice
  case "$choice" in
  [Yy]* | "") return 0 ;; # Default to Y if input is empty
  [Nn]*)
    echo "Exiting."
    exit 1
    ;;
  *)
    echo "Invalid input. Enter Y, N, or press Enter for default."
    prompt_user "$1"
    ;;
  esac
}

echo "--------------------------------------------------------------------------"

command -v adb >/dev/null || {
  echo "adb not found"
  exit 1
}
command -v scrcpy >/dev/null || {
  echo "scrcpy not found"
  exit 1
}

device_ip=""
echo "[INFO] Detecting Android device..."

# 0. Already connected via adb?
device_ip=$(adb devices | awk -F'[:\t]' '/:5555/ {print $1}' | head -n1)
if [ -n "$device_ip" ]; then
  echo "[OK] Device already connected at $device_ip"
fi

# 1. Ask adb shell (USB or paired device)
if [ -z "$device_ip" ]; then
  echo "[INFO] Trying adb shell to get device IP..."
  device_ip=$(adb shell ip route 2>/dev/null | awk '{print $9}' | head -n1)
  if [ -n "$device_ip" ]; then
    echo "[OK] Device IP via adb shell: $device_ip"
    adb connect "$device_ip:5555" >/dev/null 2>&1
  fi
fi

# 2. ARP sweep (fast, safe)
if [ -z "$device_ip" ]; then
  echo "[INFO] Trying ARP sweep..."
  for ip in $(ip neigh | awk '{print $1}'); do
    if adb connect "$ip:5555" >/dev/null 2>&1; then
      device_ip="$ip"
      echo "[OK] Connected to device at $ip"
      break
    fi
  done
fi

# 3. TCP connect scan (fallback)
if [ -z "$device_ip" ]; then
  echo "[INFO] Scanning subnet for open adb (5555)..."
  for i in {1..254}; do
    ip="192.168.1.$i"
    if (echo >/dev/tcp/$ip/5555) >/dev/null 2>&1; then
      if adb connect "$ip:5555" >/dev/null 2>&1; then
        device_ip="$ip"
        echo "[OK] Found and connected to device at $ip"
        break
      fi
    fi
  done
fi

# Fallback to manual entry
echo "[WARN] Automatic detection failed."
if [ -z "$device_ip" ]; then
  read -p "Device not found automatically. Enter Device IP: " device_ip
fi

adb connect "$device_ip:5555"

echo "[OK] Using device IP: $device_ip"

echo "Using device IP: $device_ip"

echo ""

# Step 3: Connect via USB
prompt_user "Connect the device to PC via USB. Connected?"

echo ""

# Step 4: Verify USB Connection
echo "Checking device..."
adb devices
if ! adb devices | grep -q "device$"; then
  echo "No device detected. Ensure USB DEBUGGING is enabled."
  exit 1
fi

echo ""

# Step 5: Switch to TCP/IP Mode
usb_device=$(adb devices -l |
    awk '$2=="device" && $1 !~ /_adb-tls-connect/ && $1 !~ /:/ {print $1; exit}'
)
echo "Switching adb to TCP/IP mode (port 5555)..."
adb -s "$usb_device" tcpip 5555 || {
  echo "Failed to enable TCP/IP mode."
  exit 1
}

echo ""

echo "Waiting for device to start TCP/IP..."
sleep 2 # give the device some time to switch

for i in {1..5}; do
  adb connect "$device_ip:5555" && break
  echo "Retrying in 2s..."
  sleep 2
done

if ! adb devices | grep -q "$device_ip:5555"; then
  echo "Wireless connection failed after retries."
  exit 1
fi

# Step 6: Wireless Connection
echo "Connected to $device_ip:5555."

echo ""

# Step 7: Verify Wireless Connection
adb devices
if ! adb devices | grep -q "$device_ip:5555"; then
  echo "Wireless connection failed."
  exit 1
fi

echo ""

# Step 8: Disconnect USB
# echo "Disconnect USB cable."
# prompt_user "USB disconnected?"
#
# echo ""

# Step 9: Launch scrcpy
echo "--------------------------------------------------------------------------"
echo "Launching scrcpy..."
echo "--------------------------------------------------------------------------"
scrcpy -s "$device_ip:5555" || {
  echo "Failed to launch scrcpy."
  exit 1
}

echo ""

echo "Wireless scrcpy setup complete!"
