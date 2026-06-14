#!/bin/bash

################################################################################
# Burp Integration Jenkins - Setup Script
# 
# This script sets up Jenkins with required plugins and configuration
# for Dastardly integration.
#
# Prerequisites:
#   - Jenkins 2.300+
#   - Docker installed
#   - sudo access (for docker group modification)
#
# Usage:
#   ./scripts/setup.sh [jenkins_url] [jenkins_user] [jenkins_api_token]
#   ./scripts/setup.sh http://localhost:8080 admin your-api-token
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
JENKINS_URL="${1:-http://localhost:8080}"
JENKINS_USER="${2:-admin}"
JENKINS_API_TOKEN="${3:-}"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Burp Integration Jenkins Setup Script     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

# Function to check command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prerequisites check
echo -e "\n${YELLOW}Checking Prerequisites...${NC}\n"

if ! command_exists docker; then
    print_error "Docker not found. Please install Docker first."
    echo "  Visit: https://docs.docker.com/get-docker/"
    exit 1
fi
print_status "Docker is installed"

if ! docker ps > /dev/null 2>&1; then
    print_error "Docker daemon is not running or Jenkins user cannot access it"
    exit 1
fi
print_status "Docker daemon is accessible"

# Check Jenkins connectivity
echo -e "\n${YELLOW}Checking Jenkins Connectivity...${NC}\n"

if ! curl -s "$JENKINS_URL" > /dev/null 2>&1; then
    print_error "Cannot connect to Jenkins at $JENKINS_URL"
    print_info "Make sure Jenkins is running and accessible"
    exit 1
fi
print_status "Jenkins is accessible at $JENKINS_URL"

# Add Jenkins user to docker group
echo -e "\n${YELLOW}Configuring Docker Access...${NC}\n"

if id -Gn jenkins 2>/dev/null | grep -q docker; then
    print_status "Jenkins user already in docker group"
else
    print_info "Adding jenkins user to docker group..."
    if command_exists sudo; then
        sudo usermod -aG docker jenkins 2>/dev/null || {
            print_warning "Could not add jenkins to docker group (may require manual setup)"
            echo "  Run: sudo usermod -aG docker jenkins"
        }
        print_status "Jenkins user added to docker group (restart Jenkins to apply)"
    else
        print_warning "sudo not available - skipping docker group configuration"
    fi
fi

# Display required plugins
echo -e "\n${YELLOW}Required Jenkins Plugins:${NC}\n"

plugins=(
    "Pipeline: Declarative Agent API (pipeline-model-declarative)"
    "JUnit Plugin (junit)"
    "Performance Plugin (performance) [Optional]"
    "Email Extension Plugin (email-ext) [Optional]"
)

for plugin in "${plugins[@]}"; do
    echo "  • $plugin"
done

if [ -z "$JENKINS_API_TOKEN" ]; then
    print_warning "API token not provided - skipping automatic plugin installation"
    echo ""
    echo "  To install plugins automatically, run:"
    echo "  ./scripts/setup.sh $JENKINS_URL $JENKINS_USER your-api-token"
    echo ""
    echo "  Or install manually via Jenkins UI:"
    echo "  1. Manage Jenkins → Manage Plugins"
    echo "  2. Search for each plugin above"
    echo "  3. Click 'Install without restart'"
else
    print_info "Installing required plugins..."
    
    install_plugin() {
        local plugin_id="$1"
        curl -X POST -u "$JENKINS_USER:$JENKINS_API_TOKEN" \
             "$JENKINS_URL/pluginManager/installPlugins?plugins=$plugin_id:latest" \
             2>/dev/null || {
            print_warning "Could not install plugin: $plugin_id"
        }
    }
    
    # Install core plugins
    for plugin_id in "pipeline-model-declarative" "junit"; do
        print_status "Installing $plugin_id..."
        install_plugin "$plugin_id"
    done
fi

# Create test workspace
echo -e "\n${YELLOW}Setting Up Workspace...${NC}\n"

WORKSPACE="${HOME}/burp-jenkins-workspace"
mkdir -p "$WORKSPACE"
print_status "Created workspace at $WORKSPACE"

# Docker pull latest image
echo -e "\n${YELLOW}Pulling Dastardly Image...${NC}\n"

print_info "Pulling latest Dastardly image from ECR..."
docker pull public.ecr.aws/portswigger/dastardly:latest || {
    print_warning "Could not pull Dastardly image - network issue?"
}
print_status "Dastardly image pulled"

# Setup completion message
echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Setup Complete! ✓                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "  1. Restart Jenkins (if docker group was modified):"
echo "     sudo systemctl restart jenkins"
echo ""
echo "  2. Create a new Pipeline job in Jenkins:"
echo "     - Dashboard → New Item"
echo "     - Name: 'burp-dastardly-scan'"
echo "     - Type: Pipeline"
echo "     - Click OK"
echo ""
echo "  3. Configure the pipeline:"
echo "     - Pipeline → Definition: Pipeline script from SCM"
echo "     - SCM: Git"
echo "     - Repo: https://github.com/sairam-bathini/burp-integration-jenkins"
echo "     - Branch: main"
echo ""
echo "  4. Run your first build:"
echo "     - Click 'Build Now'"
echo "     - Monitor progress in Console Output"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo ""
echo "  - Edit Jenkinsfile to change target URL (BURP_URL)"
echo "  - Edit dastardly-config.json for advanced scanning options"
echo "  - Review README.md for detailed troubleshooting"
echo ""

print_status "Setup script completed successfully!"
