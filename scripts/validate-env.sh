#!/bin/bash

################################################################################
# Burp Integration Jenkins - Environment Validation Script
#
# This script validates that all prerequisites are met before running
# the Dastardly security scan pipeline.
#
# Usage:
#   ./scripts/validate-env.sh
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Function to print colored output
print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((CHECKS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((CHECKS_FAILED++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((CHECKS_WARNING++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Main validation
print_header "Jenkins Dastardly Integration - Environment Validation"

# 1. Check Docker
print_header "Docker Environment"

if ! command -v docker &> /dev/null; then
    print_fail "Docker is not installed"
    print_info "Install from: https://docs.docker.com/get-docker/"
else
    print_pass "Docker is installed"
    
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | cut -d',' -f1)
    print_info "Docker version: $DOCKER_VERSION"
fi

if ! docker ps &> /dev/null; then
    print_fail "Docker daemon is not running or inaccessible"
    print_info "Run: sudo systemctl start docker"
else
    print_pass "Docker daemon is running"
fi

if docker run --rm hello-world &> /dev/null; then
    print_pass "Docker can execute containers"
else
    print_fail "Cannot execute Docker containers"
    print_info "Check Docker daemon status and permissions"
fi

# 2. Check Dastardly Image
print_header "Dastardly Image"

DASTARDLY_IMAGE="public.ecr.aws/portswigger/dastardly:latest"

if docker images | grep -q "dastardly"; then
    print_pass "Dastardly image is cached locally"
else
    print_warn "Dastardly image not found locally"
    print_info "Image will be pulled on first pipeline run"
    print_info "First run may take longer to download: ~500MB"
fi

# 3. Check Jenkins (if running locally)
print_header "Jenkins Setup"

if command -v docker-compose &> /dev/null; then
    print_pass "docker-compose is available"
else
    print_warn "docker-compose not installed (optional)"
fi

if [ -f "Jenkinsfile" ]; then
    print_pass "Jenkinsfile found in repository"
else
    print_fail "Jenkinsfile not found"
fi

if [ -f "dastardly-config.json" ]; then
    print_pass "Dastardly configuration file found"
else
    print_warn "dastardly-config.json not found (optional)"
fi

# 4. Check Network/Connectivity
print_header "Network Connectivity"

BURP_URL="https://ginandjuice.shop/"

if curl -s -m 5 "$BURP_URL" > /dev/null 2>&1; then
    print_pass "Target URL is accessible: $BURP_URL"
else
    print_warn "Cannot reach target URL: $BURP_URL"
    print_info "Verify that:"
    print_info "  - Network connectivity is available"
    print_info "  - Target URL is correct (edit Jenkinsfile BURP_URL)"
    print_info "  - No firewall blocking the connection"
fi

# Test DNS resolution
if host ginandjuice.shop &> /dev/null || ping -c 1 -W 1 ginandjuice.shop &> /dev/null; then
    print_pass "DNS resolution works"
else
    print_warn "May have DNS issues (optional check)"
fi

# 5. Check System Resources
print_header "System Resources"

if command -v free &> /dev/null; then
    FREE_MEM=$(free -m | awk 'NR==2{print $7}')
    if [ "$FREE_MEM" -gt 500 ]; then
        print_pass "Sufficient memory available: ${FREE_MEM}MB"
    else
        print_warn "Low free memory: ${FREE_MEM}MB (recommend 1GB+)"
    fi
fi

if command -v df &> /dev/null; then
    FREE_DISK=$(df -m / | awk 'NR==2{print $4}')
    if [ "$FREE_DISK" -gt 2000 ]; then
        print_pass "Sufficient disk space: ${FREE_DISK}MB"
    else
        print_warn "Low disk space: ${FREE_DISK}MB (recommend 5GB+)"
    fi
fi

# 6. Check Jenkins User Permissions
print_header "Jenkins User Configuration"

if id jenkins &> /dev/null; then
    print_pass "Jenkins user exists"
    
    if id -Gn jenkins 2>/dev/null | grep -q docker; then
        print_pass "Jenkins user is in docker group"
    else
        print_warn "Jenkins user not in docker group"
        print_info "Run: sudo usermod -aG docker jenkins"
    fi
else
    print_warn "Jenkins user not found (might be running as different user)"
fi

# 7. Summary
print_header "Validation Summary"

echo ""
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
[ $CHECKS_WARNING -gt 0 ] && echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
[ $CHECKS_FAILED -gt 0 ] && echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "You can now:"
    echo "  1. Create a new Pipeline job in Jenkins"
    echo "  2. Point it to this repository"
    echo "  3. Run 'Build Now' to start the security scan"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some critical checks failed!${NC}"
    echo ""
    echo "Please fix the issues above before running the pipeline."
    echo ""
    exit 1
fi
