# Burp Suite Dastardly Jenkins Integration

A Jenkins pipeline for automating security scanning using Burp Suite's Dastardly container image.

## Overview

This pipeline integrates **Dastardly** (Burp Suite's lightweight DAST scanner) into Jenkins for automated security testing. It scans web applications for common vulnerabilities including OWASP Top 10 issues.

## Prerequisites

### Required
- **Jenkins** (2.300+)
- **Docker** installed and running on the Jenkins agent
- **Docker daemon** accessible to Jenkins user
- Network access to scan target URL

### Jenkins Plugins
- Pipeline (Declarative Pipeline support)
- JUnit Plugin (for test result reporting)

### Optional
- Performance Plugin (for trend analysis)
- Email Extension Plugin (for notifications)

## Features

✅ **Automated Security Scanning** - Runs Dastardly container with configuration  
✅ **Report Generation** - Creates JUnit-formatted XML reports  
✅ **Error Handling** - Validates report generation and provides detailed logging  
✅ **Resource Management** - Cleans up Docker resources after execution  
✅ **Build Timeout** - Prevents hanging builds (30-minute limit)  
✅ **Timestamped Logs** - Enhanced debugging with timestamps  

## Configuration

### Environment Variables

Edit the `environment` block in the Jenkinsfile to customize:

```groovy
BURP_URL = 'https://ginandjuice.shop/'          // Target URL to scan
DASTARDLY_IMAGE = 'public.ecr.aws/portswigger/dastardly:latest'  // Image version
```

### Customization Examples

#### Change Target URL
```groovy
BURP_URL = 'https://your-app.com/'
```

#### Change Docker Image
```groovy
DASTARDLY_IMAGE = 'public.ecr.aws/portswigger/dastardly:v2.0.0'
```

#### Adjust Timeout
```groovy
timeout(time: 60, unit: 'MINUTES')  // Increase to 60 minutes
```

## Pipeline Stages

1. **Preparation** - Initializes pipeline, displays workspace info
2. **Docker Pull** - Pulls latest Dastardly image from ECR
3. **Docker Run** - Executes security scan in Docker container
4. **Verify Report** - Validates that the scan report was generated
5. **Post Actions** - Publishes results, cleans up resources

## Jenkins Setup

### 1. Create a New Pipeline Job
```
New Item → Pipeline → OK
```

### 2. Configure Pipeline
```
Pipeline → Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/sairam-bathini/burp-integration-jenkins
Branch: main
```

### 3. Verify Docker Access
Run this on your Jenkins agent:
```bash
docker ps
```

If permission denied, add Jenkins user to docker group:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## Usage

### Trigger Pipeline
- **Manual** - Click "Build Now"
- **SCM Polling** - Configure "Build Triggers"
- **Webhook** - Configure GitHub webhooks for push events

### View Results
1. Go to build number → Console Output
2. Check "Test Results" for vulnerability details
3. View `dastardly-report.xml` in workspace

## Report Format

The pipeline generates a JUnit-formatted XML report at:
```
${WORKSPACE}/dastardly-report.xml
```

Jenkins parses this automatically and displays:
- Total vulnerabilities found
- Severity breakdown
- Test pass/fail status

## Troubleshooting

### Docker Not Found
```
ERROR: docker: command not found
```
**Solution:** Install Docker on Jenkins agent
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Permission Denied
```
ERROR: permission denied while trying to connect to Docker daemon
```
**Solution:** Add Jenkins user to docker group
```bash
sudo usermod -aG docker jenkins
sudo newgrp docker
sudo systemctl restart jenkins
```

### Report File Not Found
```
ERROR: Report file not found at ${WORKSPACE}/dastardly-report.xml
```
**Solution:** Check Dastardly image logs
```groovy
sh 'docker logs ${CONTAINER_ID}'
```

### Network Timeout
```
ERROR: Connection refused / timeout
```
**Solution:** Verify target URL is accessible from Jenkins agent
```bash
curl -v https://ginandjuice.shop/
```

## Security Considerations

- ⚠️ **Target URL** - Only scan applications you own/have permission to test
- 🔒 **Credentials** - Use Jenkins Credentials Store for sensitive data
- 🛡️ **Network** - Run within secure network or VPN if scanning private apps
- 📋 **Compliance** - Ensure scanning complies with your security policies

## Dastardly Documentation

For more details on Dastardly:
- [Dastardly on Docker Hub](https://hub.docker.com/r/portswigger/dastardly)
- [Burp Suite Documentation](https://portswigger.net/burp)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

## License

This integration is provided as-is for security testing purposes.

## Support

For issues or questions:
1. Check Jenkins logs: `Manage Jenkins → System Log`
2. Review pipeline output in build console
3. Verify Docker daemon is running: `docker ps`
4. Check network connectivity to target URL
