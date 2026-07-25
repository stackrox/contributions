#!/bin/bash

# Export Risk Information Script
# This script exports risk information from a specific deployment via API

set -euo pipefail

# Configuration
DEFAULT_API_BASE_URL="https://api.example.com"
DEFAULT_OUTPUT_FILE="risk-export-$(date +%Y%m%d-%H%M%S).json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Export risk information from a specific deployment via API.

OPTIONS:
    -d, --deployment-id DEPLOYMENT_ID    Deployment ID to export risks for (required)
    -u, --api-url URL                    API base URL (required, default: ENV:ROX_ENDPOINT)
    -t, --token TOKEN                    API authentication token (required,default: ENV:ROX_API_TOKEN)
    -o, --output FILE                    Output file path (default: $DEFAULT_OUTPUT_FILE)
    -v, --verbose                        Enable verbose output
    -h, --help                           Display this help message

EXAMPLES:
    export to timestampedfile:
    $0 -d c7c15cde-cbb2-4daa-a569-d6f1c1657b54 -t your-api-token

    export to specific file:
    $0 -d c7c15cde-cbb2-4daa-a569-d6f1c1657b54 -t your-api-token -o risks.json

    export to stdout:
    $0 -d c7c15cde-cbb2-4daa-a569-d6f1c1657b54 -t your-api-token -o -

    use specific api url:
    $0 -d c7c15cde-cbb2-4daa-a569-d6f1c1657b54 -t your-api-token -u https://stackrox.example.com

    enable verbose output:
    $0 -d c7c15cde-cbb2-4daa-a569-d6f1c1657b54 -t your-api-token -v

ENVIRONMENT VARIABLES:
    ROX_API_TOKEN                      API authentication token
    ROX_ENDPOINT                       Host for StackRox central (central.example.com)
EOF
}

# Function to log messages
log() {
    # Always log to the controlling terminal, not to redirected stdout/file
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        ERROR)
            # Error and warning logs to stderr, and force output to /dev/tty if possible
            if [ -t 2 ]; then
                # Interactive session, log to stderr as usual
                echo -e "${RED}[ERROR]${NC} $timestamp - $message" >&2
            elif [ -w /dev/tty ]; then
                # Non-interactive output, write to controlling terminal if available
                echo -e "${RED}[ERROR]${NC} $timestamp - $message" > /dev/tty
            fi
            ;;
        WARN)
            if [ -t 2 ]; then
                echo -e "${YELLOW}[WARN]${NC} $timestamp - $message" >&2
            elif [ -w /dev/tty ]; then
                echo -e "${YELLOW}[WARN]${NC} $timestamp - $message" > /dev/tty
            fi
            ;;
        INFO)
            if [[ -t 1 ]]; then
                echo -e "${GREEN}[INFO]${NC} $timestamp - $message"
            elif [ -w /dev/tty ]; then
                echo -e "${GREEN}[INFO]${NC} $timestamp - $message" > /dev/tty
            fi
            ;;
        DEBUG)
            if [[ ${VERBOSE:-false} == true ]]; then
                if [ -t 1 ]; then
                    echo -e "${BLUE}[DEBUG]${NC} $timestamp - $message"
                elif [ -w /dev/tty ]; then
                    echo -e "${BLUE}[DEBUG]${NC} $timestamp - $message" > /dev/tty
                fi
            fi
            ;;
    esac
}

# Function to validate required tools
check_dependencies() {
    local missing_tools=()

    for tool in curl jq; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log ERROR "Missing required tools: ${missing_tools[*]}"
        log ERROR "Please install the missing tools and try again"
        exit 1
    fi
}

# Function to validate API token
validate_token() {
    local token=$1
    local api_url=$2

    log DEBUG "Validating API token..."

    local response
    log DEBUG "Validating API token with URL: $api_url/v1/auth/status"
    response=$(curl -sL -w "%{http_code}" -H "Authorization: Bearer $token" "$api_url/v1/auth/status" -o /dev/null)

    if [[ $response -ne 200 ]]; then
        log ERROR "Invalid API token or authentication failed (HTTP $response)"
        return 1
    fi

    log DEBUG "API token validated successfully"
    return 0
}

# Function to get deployment info (used as the export function)
get_deployment_info() {
    local deployment_id=$1
    local token=$2
    local api_url=$3

    log DEBUG "Fetching deployment information for: $deployment_id"

    local response
    response=$(curl -sL -H "Authorization: Bearer $token" \
        -H "Accept: application/json" \
        "$api_url/v1/deploymentswithrisk/$deployment_id")

    local http_code
    http_code=$(curl -sL -w "%{http_code}" -H "Authorization: Bearer $token" \
        "$api_url/v1/deploymentswithrisk/$deployment_id" -o /dev/null)

    if [[ $http_code -ne 200 ]]; then
        log ERROR "Failed to fetch deployment info (HTTP $http_code)"
        return 1
    fi

    # Debug: Show first 200 characters of response
    log DEBUG "Deployment API response (first 200 chars): ${response:0:200}"

    # Basic format check (make sure not empty)
    if [[ -z "$response" ]]; then
        log ERROR "API returned empty response for deployment info"
        return 1
    fi

    echo "$response"
}

# Function to save output (just raw, no formatting)
save_output() {
    local data=$1
    local output_file=$2

    if [[ $output_file == "-" ]]; then
        echo "$data" | jq -r
    else
        echo "$data" | jq -r > "$output_file"
        log INFO "Risk data exported to: $output_file"
    fi
}

# Main function
main() {
    local deployment_id=""
    local api_url="${ROX_ENDPOINT:-$DEFAULT_API_BASE_URL}"
    local token="${ROX_API_TOKEN:-}"
    local output_file="$DEFAULT_OUTPUT_FILE"
    local verbose=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--deployment-id)
                deployment_id="$2"
                shift 2
                ;;
            -u|--api-url)
                api_url="$2"
                shift 2
                ;;
            -t|--token)
                token="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log ERROR "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Set verbose flag for logging
    VERBOSE=$verbose

    # Validate required parameters
    if [[ -z $deployment_id ]]; then
        log ERROR "Deployment ID is required"
        usage
        exit 1
    fi

    if [[ -z $token ]]; then
        log ERROR "API token is required"
        usage
        exit 1
    fi

    log DEBUG "Starting risk export process..."
    log DEBUG "Deployment ID: $deployment_id"
    log DEBUG "API URL: $api_url"
    log DEBUG "Output file: $output_file"

    # Check dependencies
    check_dependencies

    # Validate API token
    if ! validate_token "$token" "$api_url"; then
        exit 1
    fi

    # Get deployment info (and treat as exported risk data)
    local risk_data
    if ! risk_data=$(get_deployment_info "$deployment_id" "$token" "$api_url"); then
        log ERROR "Deployment not found or inaccessible: $deployment_id"
        exit 1
    fi

    # Save output (no formatting)
    save_output "$risk_data" "$output_file"

    log DEBUG "Risk export completed successfully"
}

# Run main function with all arguments
main "$@"
