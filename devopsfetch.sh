#!/bin/bash

# Function to display help
usage() {
    echo "Usage: devopsfetch [OPTION] [ARGUMENT]"
    echo "A tool to collect and display system information."
    echo
    echo "Options:"
    echo "  -p, --port [PORT]           Display all active ports and services, or detailed information about a specific port."
    echo "  -d, --docker [CONTAINER]    List all Docker images and containers, or detailed information about a specific container."
    echo "  -n, --nginx [DOMAIN]        Display all Nginx domains and their ports, or detailed configuration information for a specific domain."
    echo "  -u, --users [USERNAME]      List all users and their last login times, or detailed information about a specific user."
    echo "  -t, --time                  Display activities within a specified time range."
    echo "  -h, --help                  Display this help message."
}

table() {
    local -r delimiter="${1}"
    local -r headers=("${!2}")
    local -r data=("${!3}")

    # Print headers
    printf "%s\n" "${headers[*]}" | awk -v delimiter="${delimiter}" '{for (i = 1; i <= NF; i++) {printf "%-20s%s", $i, (i == NF) ? RS : delimiter}}'

    # Print data
    for ((i = 0; i < ${#data[@]}; i++)); do
        printf "%s\n" "${data[i]}" | awk -v delimiter="${delimiter}" '{for (i = 1; i <= NF; i++) {printf "%-20s%s", $i, (i == NF) ? RS : delimiter}}'
    done
}


# Function to display all active ports and services
show_ports() {
    if [ -z "$1" ]; then
        # Display all active ports with user and service information in a table format
        printf "%-20s %-10s %-10s\n" "USER" "PORT" "SERVICE"
        echo "================================================"

        ss -tuln | awk 'NR>1 {split($5, a, ":"); print a[length(a)]}' | sort -u | while read -r port; do
            lsof -i :$port -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1 {print $3, $9, $1}' | awk -v p=$port '{split($2, a, ":"); if (a[length(a)] == p) printf "%-20s %-10s %-10s\n", $1, p, $3}' | sort -u
        done

    else
        # Display detailed information for a specific port
        output=$(lsof -i :$1 -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1 {print $3, $9, $1}' | awk -v p=$1 '{split($2, a, ":"); if (a[length(a)] == p) printf "%-20s %-10s %-10s\n", $1, p, $3}')
        
        if [ -z "$output" ]; then
            echo "No service running on port $1"
        else
            printf "%-20s %-10s %-10s\n" "USER" "PORT" "SERVICE"
            echo "==============================================="
            echo "$output"
        fi
    fi
}

# Function to display Docker images and containers
show_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker daemon is not installed on this device. Install Docker Service, build image and run container"
        return
    fi

    if [ -z "$1" ]; then
        if [ "$(docker images -q)" ]; then
            docker images 
        else
            echo "No Docker images on this device."
        fi
        if [ "$(docker ps -aq)" ]; then
            docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.ID}}"
        else
            echo "No Docker containers on this device."
        fi
    else
        if docker inspect "$1" &> /dev/null; then
            docker inspect "$1" | jq '.[0] | {Name: .Name, State: .State.Status, Image: .Config.Image, ID: .Id}'
        else
            echo "No such container: $1"
        fi
    fi
}

# Function to display Nginx domains and ports
show_nginx() {
    if ! command -v nginx &> /dev/null; then
        echo "Nginx service is not installed on this device."
        return
    fi

    nginx_status=$(systemctl is-active nginx 2>/dev/null)

    if [ "$nginx_status" != "active" ]; then
        echo "Nginx service is not running. Status: $nginx_status"
        return
    fi

    if [ -z "$1" ]; then
        echo "DOMAIN                PORT             CONFIG FILE"
        echo "==================================================="
        grep -R -E 'server_name|proxy_pass' /etc/nginx/sites-enabled/ | awk -F: '{file=$1; line=$2; value=$2; if (NF>3) {for (i=4; i<=NF; i++) value=value" "$i}} /server_name/ {server_name=value; next} /proxy_pass/ {proxy=value; print server_name "\t" proxy "\t" file}' | sed 's/;//g' | sort | uniq | column -t -s $'\t'
    else
        echo "Configuration details for domain: $1"
        local config=$(grep -R -A 10 "server_name $1;" /etc/nginx/sites-enabled | sort | uniq || sed 's/^[[:space:]]*//') 
        table "Nginx config for $1" "$config"
    fi
}

# Function to display users and their last login times
show_users() {
    if [ -z "$1" ]; then
        # List the last 10 logins excluding reboots
        echo "USER   DATE            TIME   HOST"
        echo "===================================="
        last -a | grep -v 'reboot' | head -n 10 | awk '{printf "%-6s %-15s %-5s %-10s\n", $1, $4 " " $5 " " $6, $7, $8}'
    else
        # List logins for a specific user excluding reboots
        echo "USER   DATE            TIME   HOST"
        echo "====================================="
        last -a | grep "$1" | grep -v 'reboot' | head -n 10 | awk '{printf "%-6s %-15s %-5s %-10s\n", $1, $4 " " $5 " " $6, $7, $8}'
    fi
}

# Function to display activities within a specified time range
show_time() {

    if [ $# -eq 0 ]; then
        echo "Please specify a date or date range e.g 2024/07/21 or 2024-07-18 2024-07-22"
        return 1

    elif [ $# -eq 2 ]; then
        # When range of date is provided
        start_date=$(date -d "$(echo "$1" | sed 's/\//-/g')" +"%Y-%m-%d 00:00:00")
        end_date=$(date -d "$(echo "$2" | sed 's/\//-/g') + 1 day" +"%Y-%m-%d 00:00:00")

    elif [ $# -eq 1 ]; then
        # For a single date
        start_date=$(date -d "$(echo "$1" | sed 's/\//-/g')" +"%Y-%m-%d 00:00:00")
        end_date=$(date -d "$(echo "$1" | sed 's/\//-/g') + 1 day" +"%Y-%m-%d 00:00:00")

    else
        echo "Invalid Date Range input"
        return 1
    fi

    journalctl --since "$start_date" --until "$end_date"
}

# Main script logic
case "$1" in
    -p|--port)
        show_ports "$2"
        ;;
    -d|--docker)
        show_docker "$2"
        ;;
    -n|--nginx)
        show_nginx "$2"
        ;;
    -u|--users)
        show_users "$2"
        ;;
    -t|--time)
        shift
        show_time "$@"
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Invalid option: $1"
        usage
        exit 1
        ;;
esac
