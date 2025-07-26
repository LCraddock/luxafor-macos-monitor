#!/bin/bash

# SSH Tunnel Control Script
# Usage: tunnel-control.sh [start|stop] [tunnel_name]

# Add common tool paths that might be missing in SwiftBar environment
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

ACTION=$1
TUNNEL=$2
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/tunnels.conf"

# Function to get tunnel config
get_tunnel_config() {
    local tunnel_name=$1
    while IFS='|' read -r name local_port remote_spec ssh_host ssh_port description; do
        [[ "$name" =~ ^#.*$ ]] || [ -z "$name" ] && continue
        if [ "$name" = "$tunnel_name" ]; then
            echo "$local_port|$remote_spec|$ssh_host|$ssh_port|$description"
            return 0
        fi
    done < "$CONFIG_FILE"
    return 1
}

# Function to start a tunnel
start_tunnel() {
    local config=$(get_tunnel_config "$TUNNEL")
    if [ -z "$config" ]; then
        osascript -e "display notification \"Unknown tunnel: $TUNNEL\" with title \"SSH Tunnel Error\""
        exit 1
    fi
    
    IFS='|' read -r local_port remote_spec ssh_host ssh_port description <<< "$config"
    
    # Check if using SSH config (port is "config")
    if [ "$ssh_port" = "config" ]; then
        # Use SSH config alias
        echo "Running: ssh -f -N -L ${local_port}:${remote_spec} ${ssh_host}" >> /tmp/tunnel-debug.log
        ssh -f -N -L ${local_port}:${remote_spec} ${ssh_host} 2>> /tmp/tunnel-debug.log
    else
        # Use full SSH command with port
        echo "Running: ssh -f -N -L ${local_port}:${remote_spec} -p ${ssh_port} ${ssh_host}" >> /tmp/tunnel-debug.log
        ssh -f -N -L ${local_port}:${remote_spec} -p ${ssh_port} ${ssh_host} 2>> /tmp/tunnel-debug.log
    fi
    
    if [ $? -eq 0 ]; then
        osascript -e "display notification \"$description tunnel started on port $local_port\" with title \"SSH Tunnel\""
        rm -f /tmp/tunnel-debug.log
    else
        # Read error from log
        error_msg=$(tail -1 /tmp/tunnel-debug.log 2>/dev/null || echo "Unknown error")
        osascript -e "display notification \"Failed: $error_msg\" with title \"SSH Tunnel Error\""
    fi
}

# Function to stop a tunnel
stop_tunnel() {
    local config=$(get_tunnel_config "$TUNNEL")
    if [ -z "$config" ]; then
        osascript -e "display notification \"Unknown tunnel: $TUNNEL\" with title \"SSH Tunnel Error\""
        exit 1
    fi
    
    IFS='|' read -r local_port remote_spec ssh_host ssh_port description <<< "$config"
    
    # Find and kill the tunnel process
    if [ "$ssh_port" = "config" ]; then
        # For SSH config aliases, don't include port in search
        PID=$(ps aux | grep -E "ssh.*-L.*${local_port}:${remote_spec}.*${ssh_host}" | grep -v grep | awk '{print $2}')
    else
        # Include port in search for regular connections
        PID=$(ps aux | grep -E "ssh.*-L.*${local_port}:${remote_spec}.*${ssh_host}.*-p.*${ssh_port}" | grep -v grep | awk '{print $2}')
    fi
    
    if [ -n "$PID" ]; then
        kill $PID
        osascript -e "display notification \"$description tunnel stopped\" with title \"SSH Tunnel\""
    else
        osascript -e "display notification \"$description tunnel not running\" with title \"SSH Tunnel\""
    fi
}

# Main logic
case "$ACTION" in
    "start")
        start_tunnel
        ;;
    "stop")
        stop_tunnel
        ;;
    *)
        echo "Usage: $0 [start|stop] [tunnel_name]"
        exit 1
        ;;
esac