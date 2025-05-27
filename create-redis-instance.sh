#!/bin/bash

# Improved: Checks for base config, uses /etc/redis/redis.conf

BASE_CONFIG="/etc/redis/redis.conf"
INSTANCE_DIR="/etc/redis-instances"
DATA_BASE="/var/lib"
LOG_BASE="/var/log"

echo "=== Redis Multi-Instance Setup ==="

# Check that base config exists
if [ ! -f "$BASE_CONFIG" ]; then
  echo "ERROR: Base Redis config file not found at $BASE_CONFIG"
  echo "Please check the path or copy a redis.conf there."
  exit 1
fi

read -p "Enter instance name (e.g., redis6382): " INSTANCE
read -p "Enter port number for this instance: " PORT
read -s -p "Enter desired Redis password: " PASSWORD
echo ""

CONF_FILE="$INSTANCE_DIR/${INSTANCE}.conf"
DATA_DIR="$DATA_BASE/${INSTANCE}"
LOG_FILE="$LOG_BASE/${INSTANCE}.log"
PID_FILE="/var/run/${INSTANCE}.pid"

# 1. Create config directory if needed
mkdir -p "$INSTANCE_DIR"

# 2. Copy base config
cp "$BASE_CONFIG" "$CONF_FILE"

# 3. Edit config
sed -i "s/^port .*/port $PORT/" "$CONF_FILE"
sed -i "s|^dir .*|dir $DATA_DIR|" "$CONF_FILE"
sed -i "s|^pidfile .*|pidfile $PID_FILE|" "$CONF_FILE"
sed -i "s|^logfile .*|logfile $LOG_FILE|" "$CONF_FILE"

# Add password (requirepass) - handle commented or missing
if grep -q "^# *requirepass" "$CONF_FILE"; then
  sed -i "s/^# *requirepass.*/requirepass $PASSWORD/" "$CONF_FILE"
elif grep -q "^requirepass" "$CONF_FILE"; then
  sed -i "s/^requirepass.*/requirepass $PASSWORD/" "$CONF_FILE"
else
  echo "requirepass $PASSWORD" >> "$CONF_FILE"
fi

# 4. Create needed directories
mkdir -p "$DATA_DIR"
touch "$LOG_FILE"
chown redis:redis "$DATA_DIR" "$LOG_FILE"

echo "Config created at $CONF_FILE"
echo "Data dir: $DATA_DIR"
echo "Log file: $LOG_FILE"
echo "Port: $PORT"
echo "Password: $PASSWORD"
echo ""

# 5. Optionally run instance now
read -p "Start this Redis instance now? (y/n): " START_NOW
if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
  echo "Starting Redis on port $PORT..."
  sudo -u redis redis-server "$CONF_FILE" &
  echo "Instance started (use: redis-cli -p $PORT -a $PASSWORD)"
else
  echo "To start manually: sudo -u redis redis-server $CONF_FILE"
fi

echo "Done!"
