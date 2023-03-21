#!/bin/sh

# Detect elevated command prefix
if command -v sudo >/dev/null 2>&1; then
    ELEVATED_PREFIX="sudo"
elif command -v doas >/dev/null 2>&1; then
    ELEVATED_PREFIX="doas"
else
    echo "This script requires sudo or doas to run."
    exit 1
fi

# Determine the Linux distribution
if [ -f /etc/debian_version ]; then
  distribution="Debian"
elif [ -f /etc/lsb-release ]; then
  distribution=$(lsb_release -si)
elif [ -f /etc/fedora-release ]; then
  distribution="Fedora"
elif [ -f /etc/arch-release ]; then
  distribution="Arch"
elif [ -f /etc/alpine-release ]; then
  distribution="Alpine"
else
  echo "Unsupported distribution"
  exit 1
fi

# Install Docker and Docker Compose based on the Linux distribution
case "$distribution" in
  "Debian")
    # uninstall old versions
    $ELEVATED_PREFIX apt-get remove docker docker-engine docker.io containerd runc
    # Setup the repository
    $ELEVATED_PREFIX apt-get update
    $ELEVATED_PREFIX apt-get install ca-certificates curl gnupg lsb-release
    # Add Docker’s official GPG key
    $ELEVATED_PREFIX mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | $ELEVATED_PREFIX gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | $ELEVATED_PREFIX tee /etc/apt/sources.list.d/docker.list > /dev/null
    # Install Docker Engine, containerd, and Docker Compose
    $ELEVATED_PREFIX apt-get update
    $ELEVATED_PREFIX apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
    ;;
  "Ubuntu")
    # Ubuntu
    # uninstall old versions
    $ELEVATED_PREFIX apt-get remove docker docker-engine docker.io containerd runc
    # Setup the repository
    $ELEVATED_PREFIX apt-get update
    $ELEVATED_PREFIX apt-get install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    # Add Docker’s official GPG key
    $ELEVATED_PREFIX mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $ELEVATED_PREFIX gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    # Setup the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    # Install Docker engine
    # Update apt index
    $ELEVATED_PREFIX apt-get update
    # Install Docker Engine, containerd, and Docker Compose
    $ELEVATED_PREFIX apt-get update
    $ELEVATED_PREFIX apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
    ;;
  "Fedora")
    # Fedora
    $ELEVATED_PREFIX dnf install -y docker docker-compose
    # Uninstall old versions
    $ELEVATED_PREFIX dnf remove docker \
                      docker-client \
                      docker-client-latest \
                      docker-common \
                      docker-latest \
                      docker-latest-logrotate \
                      docker-logrotate \
                      docker-selinux \
                      docker-engine-selinux \
                      docker-engine
    # Setup the repository
    $ELEVATED_PREFIX dnf -y install dnf-plugins-core
    $ELEVATED_PREFIX dnf config-manager \
        --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo
    # Install docker engine
    $ELEVATED_PREFIX dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ;;
  "Arch")
    # Install from default repo
    sudo pacman -S --noconfirm docker docker-compose
    ;;
  "Alpine")
    $ELEVATED_PREFIX apk add docker docker-compose
    ;;
esac

# Determine init system type (systemd and OpenRC)
if [ -f /run/systemd/system ]; then
  # Systemd is being used
  # Enable Docker service with systemd
  $ELEVATED_PREFIX systemctl enable docker.service
  $ELEVATED_PREFIX systemctl start docker.service
#elif [ -f /sbin/openrc-init ] || [ -f /sbin/openrc ]; then
elif [ -f /sbin/openrc ]; then
  # OpenRC is being used
  # Enable Docker service with OpenRC
  $ELEVATED_PREFIX rc-update add docker boot
  $ELEVATED_PREFIX service docker start
else
  # Unknown init system
  echo "Couldn't detect init system. Please enable and start the service manually."
fi

# v2
# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    docker_installed=false
else
    docker_installed=true
fi

# Check if Docker Compose is installed
if ! command -v docker-compose >/dev/null 2>&1; then
    docker_compose_installed=false
else
    docker_compose_installed=true
fi

# Check if both Docker and Docker Compose are installed
if [ "$docker_installed" = true ] && [ "$docker_compose_installed" = true ]; then
    echo "Congratulations! Both Docker and Docker Compose are installed!"
else
    echo "Docker: $docker_installed, Docker Compose: $docker_compose_installed"
fi
