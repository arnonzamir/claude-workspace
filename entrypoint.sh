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

# Forward select env vars to SSH sessions via /etc/profile.d/
cat > /etc/profile.d/claude-env.sh << 'ENVEOF'
# Forwarded from container environment
ENVEOF
for var in ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY; do
    val=$(eval echo "\$$var")
    if [ -n "$val" ]; then
        echo "export $var=\"$val\"" >> /etc/profile.d/claude-env.sh
    fi
done
chmod 644 /etc/profile.d/claude-env.sh

# Generate host keys if missing (first run)
ssh-keygen -A 2>/dev/null

echo "=== Workspace ready, starting SSH ==="
exec /usr/sbin/sshd -D
