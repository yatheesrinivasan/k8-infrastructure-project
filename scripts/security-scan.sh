#!/bin/bash

# Container Image Vulnerability Scanner using Trivy
# This script scans container images for vulnerabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install Trivy if not present
install_trivy() {
    if ! command -v trivy &> /dev/null; then
        log_info "Installing Trivy..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            sudo apt-get update
            sudo apt-get install wget apt-transport-https gnupg lsb-release -y
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update
            sudo apt-get install trivy -y
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install trivy
            else
                log_error "Homebrew not found. Please install Trivy manually."
                exit 1
            fi
        else
            log_error "Unsupported OS. Please install Trivy manually."
            exit 1
        fi
    else
        log_info "Trivy already installed."
    fi
}

# Scan image function
scan_image() {
    local image=$1
    local severity=${2:-"HIGH,CRITICAL"}
    
    log_info "Scanning image: $image"
    log_info "Severity levels: $severity"
    
    # Run trivy scan
    trivy image --severity "$severity" --format table --light "$image"
    
    # Generate JSON report
    local report_file="security/reports/$(echo $image | sed 's/[\/:]/_/g')_$(date +%Y%m%d_%H%M%S).json"
    mkdir -p "security/reports"
    
    trivy image --severity "$severity" --format json --output "$report_file" "$image"
    
    log_info "Report saved to: $report_file"
    
    # Check if vulnerabilities found
    local vuln_count=$(cat "$report_file" | jq '.Results[].Vulnerabilities | length' 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$vuln_count" -gt 0 ]; then
        log_warn "Found $vuln_count vulnerabilities in $image"
        return 1
    else
        log_info "No vulnerabilities found in $image"
        return 0
    fi
}

# Scan Kubernetes manifests
scan_k8s_manifests() {
    local manifest_dir=${1:-"kubernetes"}
    
    log_info "Scanning Kubernetes manifests in $manifest_dir"
    
    if [ -d "$manifest_dir" ]; then
        trivy config "$manifest_dir"
    else
        log_error "Directory $manifest_dir not found"
        exit 1
    fi
}

# Main function
main() {
    local command=${1:-"help"}
    
    case $command in
        "install")
            install_trivy
            ;;
        "scan-image")
            if [ -z "$2" ]; then
                log_error "Please provide an image name"
                echo "Usage: $0 scan-image <image-name> [severity-levels]"
                exit 1
            fi
            install_trivy
            scan_image "$2" "$3"
            ;;
        "scan-k8s")
            install_trivy
            scan_k8s_manifests "$2"
            ;;
        "scan-common")
            install_trivy
            log_info "Scanning common container images..."
            
            # Common images used in the project
            images=(
                "docker.elastic.co/beats/filebeat:8.11.0"
                "prom/node-exporter:v1.6.1"
                "prom/prometheus:latest"
                "grafana/grafana:latest"
                "nginx:1.21"
                "alpine:3.18"
            )
            
            failed_scans=0
            for image in "${images[@]}"; do
                if ! scan_image "$image" "HIGH,CRITICAL"; then
                    ((failed_scans++))
                fi
                echo ""
            done
            
            if [ $failed_scans -gt 0 ]; then
                log_error "$failed_scans image(s) failed security scan"
                exit 1
            else
                log_info "All images passed security scan"
            fi
            ;;
        "help"|*)
            echo "Container Security Scanner"
            echo ""
            echo "Usage:"
            echo "  $0 install                           - Install Trivy"
            echo "  $0 scan-image <image> [severity]     - Scan specific image"
            echo "  $0 scan-k8s [manifest-dir]          - Scan Kubernetes manifests"
            echo "  $0 scan-common                       - Scan common project images"
            echo "  $0 help                              - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 scan-image nginx:latest"
            echo "  $0 scan-image alpine:3.18 MEDIUM,HIGH,CRITICAL"
            echo "  $0 scan-k8s kubernetes/"
            ;;
    esac
}

# Run main function
main "$@"