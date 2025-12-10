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

    # Special case: OSPortal API requires two-layer tunnel
    if [ "$TUNNEL" = "osportal-api" ]; then
        echo "Starting OSPortal API two-layer tunnel..." >> /tmp/tunnel-debug.log

        # Layer 1: SSH tunnel to osportal server (port 5000)
        echo "Layer 1: Starting SSH tunnel to osportal..." >> /tmp/tunnel-debug.log
        ssh -f -N -L 5000:localhost:5000 osportal 2>> /tmp/tunnel-debug.log
        sleep 1  # Wait for SSH tunnel to establish

        # Layer 2: Flask proxy with IAP headers (port 8888)
        echo "Layer 2: Starting Flask proxy..." >> /tmp/tunnel-debug.log
        script_path="$remote_spec"
        script_dir=$(dirname "$script_path")

        cd "$script_dir"
        if [ -d "$script_dir/venv" ]; then
            source "$script_dir/venv/bin/activate"
        fi
        nohup python3 "$script_path" >> /tmp/tunnel-debug.log 2>&1 &
        cd - > /dev/null

        # Verify both layers are running
        sleep 2
        if lsof -ti:5000 > /dev/null && lsof -ti:8888 > /dev/null; then
            osascript -e "display notification \"Two-layer tunnel started (SSH:5000, API:8888)\" with title \"OSPortal API\""
            rm -f /tmp/tunnel-debug.log
            return 0
        else
            error_msg=$(tail -5 /tmp/tunnel-debug.log 2>/dev/null || echo "Unknown error")
            osascript -e "display notification \"Failed to start: $error_msg\" with title \"OSPortal API Error\""
            return 1
        fi
    fi

    # Check tunnel type
    if [ "$ssh_port" = "iap" ] && [ "$ssh_host" = "gcloud" ]; then
        # Use gcloud IAP tunnel
        # Parse remote_spec as instance:port
        IFS=':' read -r instance remote_port <<< "$remote_spec"
        echo "Running: gcloud compute start-iap-tunnel $instance $remote_port --local-host-port=localhost:$local_port --zone=us-east1-b --project=security-testing-237816" >> /tmp/tunnel-debug.log
        gcloud compute start-iap-tunnel "$instance" "$remote_port" --local-host-port="localhost:$local_port" --zone=us-east1-b --project=security-testing-237816 2>> /tmp/tunnel-debug.log &
    elif [ "$ssh_port" = "compute-ssh" ] && [ "$ssh_host" = "gcloud" ]; then
        # Use gcloud compute ssh with port forwarding (background)
        # remote_spec contains the VM name
        vm_name="$remote_spec"

        echo "Running: gcloud compute ssh larry@${vm_name} --zone=us-east1-d --project=nonprod-security-testing -- -f -N -p822 -L ${local_port}:127.0.0.1:${local_port}" >> /tmp/tunnel-debug.log
        gcloud compute ssh "larry@${vm_name}" \
            --zone=us-east1-d \
            --project=nonprod-security-testing \
            -- -f -N -p822 -L "${local_port}:127.0.0.1:${local_port}" 2>> /tmp/tunnel-debug.log

        # Wait for tunnel to establish
        sleep 2

        # Auto-open browser
        open "http://localhost:${local_port}"
    elif [ "$ssh_port" = "flask" ] && [ "$ssh_host" = "python" ]; then
        # Use Python Flask app
        # remote_spec contains the path to the Python script
        script_path="$remote_spec"
        script_dir=$(dirname "$script_path")

        echo "Running Flask app: $script_path" >> /tmp/tunnel-debug.log
        cd "$script_dir"

        # Check if venv exists and activate it
        if [ -d "$script_dir/venv" ]; then
            source "$script_dir/venv/bin/activate"
        fi

        # Run the Python script in background
        nohup python3 "$script_path" >> /tmp/tunnel-debug.log 2>&1 &

        # Return to original directory
        cd - > /dev/null
    elif [ "$ssh_port" = "webserver" ] && [ "$ssh_host" = "python" ]; then
        # Use Python web server (http.server, etc.)
        # remote_spec contains the path to the launcher script
        script_path="$remote_spec"

        echo "Running web server: $script_path" >> /tmp/tunnel-debug.log

        # Run the launcher script in background
        nohup "$script_path" >> /tmp/tunnel-debug.log 2>&1 &
    elif [ "$ssh_port" = "reverse-config" ]; then
        # Use SSH config alias with reverse tunnel
        echo "Running: ssh -f -N -R ${local_port}:${remote_spec} ${ssh_host}" >> /tmp/tunnel-debug.log
        ssh -f -N -R ${local_port}:${remote_spec} ${ssh_host} 2>> /tmp/tunnel-debug.log
    elif [ "$ssh_port" = "reverse" ]; then
        # Use reverse tunnel with explicit host/port
        # For reverse tunnels: ssh -R remote_port:destination:dest_port user@ssh_server
        # Here: ssh_host contains user@server, remote_spec contains destination:port
        # local_port is the port to open on the remote server
        echo "Running: ssh -f -N -R ${local_port}:${remote_spec} ${ssh_host}" >> /tmp/tunnel-debug.log
        ssh -f -N -R ${local_port}:${remote_spec} ${ssh_host} 2>> /tmp/tunnel-debug.log
    elif [ "$ssh_port" = "config" ]; then
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

    # Special case: OSPortal API two-layer tunnel
    if [ "$TUNNEL" = "osportal-api" ]; then
        echo "Stopping OSPortal API two-layer tunnel..." >> /tmp/tunnel-debug.log

        # Kill Flask proxy (Layer 2)
        FLASK_PID=$(ps aux | grep -E "python.*osportal_api\.py" | grep -v grep | awk '{print $2}')
        if [ -n "$FLASK_PID" ]; then
            echo "Stopping Flask proxy (PID: $FLASK_PID)..." >> /tmp/tunnel-debug.log
            kill $FLASK_PID
        fi

        # Kill SSH tunnel (Layer 1)
        SSH_PID=$(ps aux | grep -E "ssh.*-L.*5000:localhost:5000.*osportal" | grep -v grep | awk '{print $2}')
        if [ -n "$SSH_PID" ]; then
            echo "Stopping SSH tunnel (PID: $SSH_PID)..." >> /tmp/tunnel-debug.log
            kill $SSH_PID
        fi

        if [ -n "$FLASK_PID" ] || [ -n "$SSH_PID" ]; then
            osascript -e "display notification \"Two-layer tunnel stopped\" with title \"OSPortal API\""
        else
            osascript -e "display notification \"Tunnel not running\" with title \"OSPortal API\""
        fi
        return 0
    fi

    # Find and kill the tunnel process
    if [ "$ssh_port" = "iap" ] && [ "$ssh_host" = "gcloud" ]; then
        # For gcloud IAP tunnels
        IFS=':' read -r instance remote_port <<< "$remote_spec"
        PID=$(ps aux | grep -E "gcloud.*start-iap-tunnel.*${instance}.*${remote_port}.*${local_port}" | grep -v grep | awk '{print $2}')
    elif [ "$ssh_port" = "compute-ssh" ] && [ "$ssh_host" = "gcloud" ]; then
        # For gcloud compute ssh tunnels (detects the underlying SSH process)
        # gcloud creates an SSH subprocess, so we look for SSH with the port forward
        PID=$(ps aux | grep -E "ssh.*google_compute_engine.*-L.*${local_port}:127\.0\.0\.1:${local_port}" | grep -v grep | awk '{print $2}' | head -1)
    elif [ "$ssh_port" = "flask" ] && [ "$ssh_host" = "python" ]; then
        # For Python Flask apps
        script_name=$(basename "$remote_spec")
        PID=$(ps aux | grep -E "python.*${script_name}" | grep -v grep | awk '{print $2}')
    elif [ "$ssh_port" = "webserver" ] && [ "$ssh_host" = "python" ]; then
        # For Python web servers - find the python process
        # The launcher script starts python, so look for the .py file
        PID=$(ps aux | grep -E "python.*claude_session_browser\.py" | grep -v grep | awk '{print $2}')
    elif [ "$ssh_port" = "reverse-config" ]; then
        # For SSH config aliases with reverse tunnel, search for -R flag
        PID=$(ps aux | grep -E "ssh.*-R.*${local_port}:${remote_spec}.*${ssh_host}" | grep -v grep | awk '{print $2}')
    elif [ "$ssh_port" = "reverse" ]; then
        # For reverse tunnels, search for -R flag
        PID=$(ps aux | grep -E "ssh.*-R.*${local_port}:${remote_spec}.*${ssh_host}" | grep -v grep | awk '{print $2}')
    elif [ "$ssh_port" = "config" ]; then
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