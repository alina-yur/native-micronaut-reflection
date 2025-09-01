#!/bin/bash

COUNT=50
BASE_PORT=56000
BIN=./target/demo-pie-rcp

PIDS=()
for ((i=1; i<=COUNT; i++)); do
  PORT=$((BASE_PORT + i))
  "$BIN" --server.port="$PORT" >/dev/null 2>&1 &
  PIDS+=($!)
done

sleep 8

echo "Measuring Relative PIE footprints and dirty pages:"
for pid in "${PIDS[@]}"; do
  # Physical footprint (exclude the '(peak)' line; get the first match only)
  FP=$(vmmap -resident -summary "$pid" 2>/dev/null \
      | awk -F':' '/^Physical footprint[[:space:]]*\:/{gsub(/^[ \t]+/,"",$2); print $2; exit}')

  # Dirty = column 3 of the LAST TOTAL line in -summary (avoids MALLOC ZONE TOTAL)
  DIRTY=$(vmmap -summary "$pid" 2>/dev/null \
      | awk '/^TOTAL/{last=$0} END{print last}' \
      | awk '{print $3}')

  echo "PID $pid: ${FP:-N/A} footprint, ${DIRTY:-N/A} dirty"
done

kill "${PIDS[@]}" 2>/dev/null
wait
