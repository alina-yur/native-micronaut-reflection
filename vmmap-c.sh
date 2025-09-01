#!/bin/bash

echo "=== Testing Standard PIE ==="
# Launch 5 instances of standard PIE
PIDS_STANDARD=()
for i in {1..5}; do
    ./target/demo-pie --server.port=808$i &
    PIDS_STANDARD+=($!)
done

sleep 10  # Let them fully start

echo "Measuring Standard PIE memory:"
TOTAL_DIRTY_STANDARD=0
for pid in "${PIDS_STANDARD[@]}"; do
    # Get the dirty memory from first TOTAL line, column 4
    DIRTY_RAW=$(vmmap -summary $pid | grep "TOTAL" | head -1 | awk '{print $4}')
    echo "PID $pid: $DIRTY_RAW dirty"
    
    # Convert to MB for calculation
    if [[ $DIRTY_RAW == *"M" ]]; then
        DIRTY=$(echo $DIRTY_RAW | sed 's/M//')
    elif [[ $DIRTY_RAW == *"K" ]]; then
        DIRTY_K=$(echo $DIRTY_RAW | sed 's/K//')
        DIRTY=$(echo "scale=2; $DIRTY_K / 1024" | bc)
    else
        echo "Warning: Could not parse memory for PID $pid (got: $DIRTY_RAW)"
        DIRTY=0
    fi
    
    TOTAL_DIRTY_STANDARD=$(echo "scale=2; $TOTAL_DIRTY_STANDARD + $DIRTY" | bc)
done

# Kill standard PIE instances
kill "${PIDS_STANDARD[@]}" 2>/dev/null
wait

echo ""
echo "=== Testing Relative PIE ==="
# Launch 5 instances of relative PIE
PIDS_RELATIVE=()
for i in {1..5}; do
    ./target/demo-pie-rcp --server.port=809$i &
    PIDS_RELATIVE+=($!)
done

sleep 10

echo "Measuring Relative PIE memory:"
TOTAL_DIRTY_RELATIVE=0
for pid in "${PIDS_RELATIVE[@]}"; do
    # Get the dirty memory from first TOTAL line, column 4 (SAME as standard PIE)
    DIRTY_RAW=$(vmmap -summary $pid | grep "TOTAL" | head -1 | awk '{print $4}')
    echo "PID $pid: $DIRTY_RAW dirty"
    
    # Convert to MB for calculation
    if [[ $DIRTY_RAW == *"M" ]]; then
        DIRTY=$(echo $DIRTY_RAW | sed 's/M//')
    elif [[ $DIRTY_RAW == *"K" ]]; then
        DIRTY_K=$(echo $DIRTY_RAW | sed 's/K//')
        DIRTY=$(echo "scale=2; $DIRTY_K / 1024" | bc)
    else
        echo "Warning: Could not parse memory for PID $pid (got: $DIRTY_RAW)"
        DIRTY=0
    fi
    
    TOTAL_DIRTY_RELATIVE=$(echo "scale=2; $TOTAL_DIRTY_RELATIVE + $DIRTY" | bc)
done

echo ""
echo "=== Results ==="
echo "Standard PIE total dirty: ${TOTAL_DIRTY_STANDARD}M"
echo "Relative PIE total dirty: ${TOTAL_DIRTY_RELATIVE}M"

# Calculate savings (could be negative if relative PIE uses more memory)
SAVINGS=$(echo "scale=2; $TOTAL_DIRTY_STANDARD - $TOTAL_DIRTY_RELATIVE" | bc)
if (( $(echo "$SAVINGS >= 0" | bc -l) )); then
    echo "Memory savings: ${SAVINGS}M"
else
    INCREASE=$(echo "scale=2; $SAVINGS * -1" | bc)
    echo "Memory increase: ${INCREASE}M"
fi

# Calculate percentage difference
if (( $(echo "$TOTAL_DIRTY_STANDARD > 0" | bc -l) )); then
    PERCENT=$(echo "scale=2; ($SAVINGS / $TOTAL_DIRTY_STANDARD) * 100" | bc)
    if (( $(echo "$SAVINGS >= 0" | bc -l) )); then
        echo "Percentage savings: ${PERCENT}%"
    else
        PERCENT_ABS=$(echo "scale=2; $PERCENT * -1" | bc)
        echo "Percentage increase: ${PERCENT_ABS}%"
    fi
fi

echo ""
echo "=== Per-Process Averages ==="
if (( ${#PIDS_STANDARD[@]} > 0 )); then
    AVG_STANDARD=$(echo "scale=2; $TOTAL_DIRTY_STANDARD / ${#PIDS_STANDARD[@]}" | bc)
    echo "Standard PIE average: ${AVG_STANDARD}M per process"
fi

if (( ${#PIDS_RELATIVE[@]} > 0 )); then
    AVG_RELATIVE=$(echo "scale=2; $TOTAL_DIRTY_RELATIVE / ${#PIDS_RELATIVE[@]}" | bc)
    echo "Relative PIE average: ${AVG_RELATIVE}M per process"
fi

# Cleanup
kill "${PIDS_RELATIVE[@]}" 2>/dev/null