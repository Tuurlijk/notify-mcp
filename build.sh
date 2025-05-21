#!/bin/sh

# Ensure the script exits on any error
set -e

# Build the Rust application for a minimal static binary
cargo build --release --target=x86_64-unknown-linux-musl

# Create the target directory for the binary if it doesn't exist
mkdir -p $HOME/bin

# Copy the compiled binary
cp target/x86_64-unknown-linux-musl/release/notify-mcp $HOME/bin/notify-mcp

# Optional: Compress the binary with UPX if available
if command -v upx >/dev/null 2>&1; then
  echo "UPX found, compressing binary..."
  upx --best --lzma $HOME/bin/notify-mcp
else
  echo "UPX not found, skipping compression."
fi

# Build the Docker image (UID/GID are now runtime concerns)
echo "Building Docker image (generic appuser defined)..."
docker build -t michielroos/notify-mcp -f Dockerfile .

# Stop and remove any existing container with the same name
echo "Stopping and removing existing container (if any)..."
docker stop notify-mcp-container >/dev/null 2>&1 || true
docker rm notify-mcp-container >/dev/null 2>&1 || true

# --- Runtime Configuration ---

# Default port
PORT=${PORT:-3000}

# Configurable runtime UID/GID (default to current user's UID/GID or 1000)
APP_UID=${APP_UID:-$(id -u)}
APP_GID=${APP_GID:-$(id -g)}

if [ -z "$APP_UID" ]; then APP_UID=1000; fi
if [ -z "$APP_GID" ]; then APP_GID=1000; fi

echo "Will run container as UID=$APP_UID and GID=$APP_GID."


# Ensure XDG_RUNTIME_DIR is set for the D-Bus socket path on the host
if [ -z "$XDG_RUNTIME_DIR" ]; then
  echo "Error: Host XDG_RUNTIME_DIR is not set. Cannot determine D-Bus socket path."
  echo "Please ensure you are running this script in a graphical session or XDG_RUNTIME_DIR is manually set."
  exit 1
fi

HOST_DBUS_SOCKET_PATH="$XDG_RUNTIME_DIR/bus"

if [ ! -S "$HOST_DBUS_SOCKET_PATH" ]; then # -S checks if it's a socket
    echo "Error: D-Bus socket not found at $HOST_DBUS_SOCKET_PATH on the host, or it is not a socket."
    echo "Ensure D-Bus is running and XDG_RUNTIME_DIR is correctly set."
    exit 1
fi

# Define D-Bus paths inside the container based on the runtime APP_UID
CONTAINER_XDG_RUNTIME_DIR="/run/user/$APP_UID"
CONTAINER_DBUS_SOCKET_PATH="$CONTAINER_XDG_RUNTIME_DIR/bus"

# Run the Docker container with D-Bus and environment variables mounted
echo "Running Docker container with D-Bus access..."
docker run -d --name notify-mcp-container \
  --user $APP_UID:$APP_GID \
  -e PORT=$PORT \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=$CONTAINER_DBUS_SOCKET_PATH" \
  -e XDG_RUNTIME_DIR="$CONTAINER_XDG_RUNTIME_DIR" \
  -v "$HOST_DBUS_SOCKET_PATH:$CONTAINER_DBUS_SOCKET_PATH:ro" \
  -p $PORT:$PORT \
  michielroos/notify-mcp

echo "Notify MCP Server should be running in a Docker container on port $PORT as UID=$APP_UID, GID=$APP_GID."
echo "The D-Bus socket from $HOST_DBUS_SOCKET_PATH has been mounted to $CONTAINER_DBUS_SOCKET_PATH inside the container."