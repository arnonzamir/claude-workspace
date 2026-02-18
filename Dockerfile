FROM node:20-bookworm

# Install system packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssh-server \
    sudo \
    git \
    vim \
    tmux \
    htop \
    zsh \
    curl \
    wget \
    jq \
    ripgrep \
    fzf \
    less \
    man-db \
    locales \
    # Remote desktop + browser
    xvfb \
    x11vnc \
    novnc \
    websockify \
    chromium \
    dbus-x11 \
    xdg-utils \
    # Lightweight window manager
    openbox \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd (web terminal)
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Set up locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create user with sudo
RUN useradd -m -s /bin/bash -G sudo arnon && \
    echo 'arnon ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Set chromium as default browser so claude login can find it
RUN update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/chromium 200 && \
    update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/chromium 200
ENV BROWSER=/usr/bin/chromium

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 7681 6080

CMD ["/entrypoint.sh"]
