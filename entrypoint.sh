#!/bin/bash
set -e

# Set up SSH public key from environment variable
if [ -n "$SSH_PUBLIC_KEY" ]; then
    mkdir -p /home/arnon/.ssh
    echo "$SSH_PUBLIC_KEY" > /home/arnon/.ssh/authorized_keys
    chown -R arnon:arnon /home/arnon/.ssh
    chmod 700 /home/arnon/.ssh
    chmod 600 /home/arnon/.ssh/authorized_keys
fi

# Generate host keys if missing (first run)
ssh-keygen -A 2>/dev/null

echo "=== Workspace ready, starting SSH ==="
exec /usr/sbin/sshd -D
