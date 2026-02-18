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

# Forward select env vars to SSH sessions and ttyd
cat > /etc/profile.d/claude-env.sh << 'ENVEOF'
# Forwarded from container environment
export DISPLAY=:99
ENVEOF
for var in ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY; do
    val=$(eval echo "\$$var")
    if [ -n "$val" ]; then
        echo "export $var=\"$val\"" >> /etc/profile.d/claude-env.sh
    fi
done
chmod 644 /etc/profile.d/claude-env.sh

# Generate SSH host keys if missing
ssh-keygen -A 2>/dev/null

# Start SSH
/usr/sbin/sshd

# Start virtual display
export DISPLAY=:99
Xvfb :99 -screen 0 1280x800x24 &
sleep 1

# Start lightweight window manager
openbox &

# Start VNC server on the virtual display
x11vnc -display :99 -forever -nopw -shared -rfbport 5900 &

# Start noVNC (web-based VNC client) on port 6080
websockify --web /usr/share/novnc 6080 localhost:5900 &

echo "=== Remote desktop ready on port 6080 ==="

# Start ttyd (web terminal) as main process
echo "=== Starting web terminal on port 7681 ==="
TTYD_OPTS="-p 7681 -t fontSize=14"
if [ -n "$TTYD_PASSWORD" ]; then
    exec ttyd $TTYD_OPTS -c "arnon:${TTYD_PASSWORD}" login -f arnon
else
    exec ttyd $TTYD_OPTS login -f arnon
fi
