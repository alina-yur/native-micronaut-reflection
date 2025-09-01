#!/bin/bash

PIDS=()
for i in {1..10}; do
  ./target/demo-pie-rcp --server.port=$((54460+i)) >/dev/null 2>&1 &
  PIDS+=($!)
done

sleep 6

echo "Measuring Relative PIE footprints and dirty pages:"
for pid in "${PIDS[@]}"; do
  FP=$(vmmap -resident -summary "$pid" 2>/dev/null \
       | awk -F':' '/Physical footprint/{gsub(/^[ \t]+/,"",$2); print $2}')
  DIRTY=$(vmmap -summary "$pid" 2>/dev/null \
       | awk '/^TOTAL/{print $3}')
  echo "PID $pid: ${FP:-N/A} footprint, ${DIRTY:-N/A} dirty"
done

kill "${PIDS[@]}" 2>/dev/null
wait
