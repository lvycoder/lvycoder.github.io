#!/bin/bash

# List of hosts
HOSTS=(
    "sh01" "sh02" "sh03"
)

# Temporary directory to store individual host info
TMP_DIR="/tmp/hardware_info"
mkdir -p "$TMP_DIR"

# Function to gather hardware info from a host
gather_info() {
    local HOST=$1
    local INFO_FILE="$TMP_DIR/${HOST}_hardware_info.txt"

    echo "Gathering info for $HOST..."

    # Run neofetch and save the output to a variable
    NEFETCH_OUTPUT=$(ssh "$HOST" "neofetch --stdout" 2>/dev/null)

    # Extract the required information using awk
    HOSTNAME=$(ssh "$HOST" "hostname" 2>/dev/null)
    HOST_MODEL=$(echo "$NEFETCH_OUTPUT" | awk -F': ' '/Host:/ {print $2}')
    CPU_MODEL=$(echo "$NEFETCH_OUTPUT" | awk -F': ' '/CPU:/ {print $2}')

    # Extract GPU information using nvidia-smi
    GPU_INFO=$(ssh "$HOST" "nvidia-smi -L" 2>/dev/null | awk -F': ' '{print $2}' | awk -F' ' '{print $1, $2, $3, $4, $5, $6}' | sort | uniq -c | awk '{print $2 " " $3 " " $4 " " $5 " " $6 " * " $1}')
    if [ -z "$GPU_INFO" ]; then
        GPU_INFO="None"
    fi

    # Get disk info
    DISK_INFO=$(ssh "$HOST" "lsblk -d -o model" 2>/dev/null | grep -v 'MODEL' | sort | uniq -c | awk '{print $2 " * " $1}')

    # Combine and save the info
    echo -e "Host: $HOSTNAME\nModel: $HOST_MODEL\nCPU: $CPU_MODEL\nGPU: $GPU_INFO\nDisk:\n$DISK_INFO" > "$INFO_FILE"
}

# Gather info from all hosts
for HOST in "${HOSTS[@]}"; do
    gather_info "$HOST" &
done

# Wait for all background jobs to finish
wait

# Create a Markdown file
OUTPUT_FILE="shanghai_server_info.md"
{
    echo "| 主机名 | 主机型号 | CPU | GPU 型号和数量 | 硬盘型号及数量 |"
    echo "| --- | --- | --- | --- | --- |"

    for HOST in "${HOSTS[@]}"; do
        INFO_FILE="$TMP_DIR/${HOST}_hardware_info.txt"
        if [ -f "$INFO_FILE" ]; then
            HOSTNAME=$(grep "Host" "$INFO_FILE" | cut -d' ' -f2-)
            MODEL=$(grep "Model" "$INFO_FILE" | cut -d' ' -f2-)
            CPU=$(grep "CPU" "$INFO_FILE" | cut -d' ' -f2-)
            GPU=$(grep "GPU" "$INFO_FILE" | cut -d' ' -f2-)
            DISK=$(grep -A 100 "Disk" "$INFO_FILE" | tail -n +2 | xargs | sed 's/ /, /g')
            echo "| $HOSTNAME | $MODEL | $CPU | $GPU | $DISK |"
        else
            echo "| $HOST | Error collecting info | N/A | N/A | N/A |"
        fi
    done
} > "$OUTPUT_FILE"

echo "Markdown file saved as $OUTPUT_FILE."