#!/bin/sh

set -e

echo "Building Rust application for x86_64-unknown-linux-musl..."
cargo build --release --target=x86_64-unknown-linux-musl

echo "Building Docker image (michielroos/notify-mcp)..."
docker build -t michielroos/notify-mcp -f Dockerfile .

echo "Docker image michielroos/notify-mcp built successfully."
echo "You can now use run.sh to start the container."