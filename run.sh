#!/bin/sh

# Ensure the script exits on any error
set -e

CONTAINER_NAME="notify-mcp-container"
IMAGE_NAME="michielroos/notify-mcp"

# Stop and remove any existing container with the same name
echo "Stopping and removing existing container '$CONTAINER_NAME' (if any)..."
docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
docker rm $CONTAINER_NAME >/dev/null 2>&1 || true

# --- Runtime Configuration ---

# Default port, can be overridden by environment variable PORT
PORT=${PORT:-3000}

# Configurable runtime UID/GID (default to current user's UID/GID or 1000 if those fail)
APP_UID=${APP_UID:-$(id -u 2>/dev/null || echo 1000)}
APP_GID=${APP_GID:-$(id -g 2>/dev/null || echo 1000)}

echo "Preparing to run container '$CONTAINER_NAME' from image '$IMAGE_NAME' as UID=$APP_UID, GID=$APP_GID on port $PORT."

# Ensure XDG_RUNTIME_DIR is set for the D-Bus socket path on the host
if [ -z "$XDG_RUNTIME_DIR" ]; then
  echo "Error: Host XDG_RUNTIME_DIR is not set. Cannot determine D-Bus socket path."
  echo "Please ensure you are running this script in a graphical session or XDG_RUNTIME_DIR is manually set."
  exit 1
fi

HOST_DBUS_SOCKET_PATH="$XDG_RUNTIME_DIR/bus"

if [ ! -S "$HOST_DBUS_SOCKET_PATH" ]; then # -S checks if it's a socket
    echo "Error: D-Bus socket not found at $HOST_DBUS_SOCKET_PATH on the host, or it is not a socket."
    echo "Ensure D-Bus is running and XDG_RUNTIME_DIR is correctly set on the host."
    exit 1
fi

# Define D-Bus paths inside the container based on the runtime APP_UID
CONTAINER_XDG_RUNTIME_DIR="/run/user/$APP_UID"
CONTAINER_DBUS_SOCKET_PATH="$CONTAINER_XDG_RUNTIME_DIR/bus"

# Run the Docker container with D-Bus and environment variables mounted
echo "Starting container '$CONTAINER_NAME'..."
docker run -d --name $CONTAINER_NAME \
  --user $APP_UID:$APP_GID \
  -e PORT=$PORT \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=$CONTAINER_DBUS_SOCKET_PATH" \
  -e XDG_RUNTIME_DIR="$CONTAINER_XDG_RUNTIME_DIR" \
  -v "$HOST_DBUS_SOCKET_PATH:$CONTAINER_DBUS_SOCKET_PATH:ro" \
  -p $PORT:$PORT \
  $IMAGE_NAME

echo "Container '$CONTAINER_NAME' started."
echo "Notify MCP Server should be running on port $PORT (host) mapped from container port $PORT."
echo "The D-Bus socket from $HOST_DBUS_SOCKET_PATH has been mounted to $CONTAINER_DBUS_SOCKET_PATH inside the container."
echo "Application inside container runs as UID=$APP_UID, GID=$APP_GID."

# Optional: Add a health check or log tailing here if desired
# echo "Tailing container logs (Ctrl+C to stop):"
# docker logs -f $CONTAINER_NAME
