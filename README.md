# Notify MCP Server 🔔

A Model Context Protocol (MCP) server that provides desktop notification functionality. This server exposes a tool that can be used by MCP clients to send desktop notifications with custom titles and messages.

This is an exploration into mcp usage and will not be of use if you run this server locally and connect it to a client that can then notify you when it is done with a task.

## Features ✨

- MCP-compliant server with SSE transport.
- Simple API for sending desktop notifications.
- Integrates with native OS notification systems.
- Docker support with runtime UID/GID configuration and D-Bus passthrough for notifications from container.
- Minimal Docker image using `FROM scratch`.

## Getting Started 🚀

### Prerequisites

- Rust toolchain (1.76.0 or later).
- A system that supports desktop notifications (Linux/macOS/Windows for local runs).
- Docker (if using the containerized version).

### Installation & Running

**1. Clone the Repository:**

```bash
git clone https://github.com/Tuurlijk/notify-mcp.git
cd notify-mcp
```

**2. Running Natively:**

```bash
cargo build --release
cargo run --release
```
The server will start (by default on `http://127.0.0.1:3000`).

**3. Building and Running with Docker (Recommended for Isolation & Portability):**

First, build the Docker image:
```bash
./build.sh
```
This script will:
- Compile the Rust application for `x86_64-unknown-linux-musl` (for a static binary).
- Build a Docker image named `michielroos/notify-mcp` using a `FROM scratch` base.

Then, run the container using the `run.sh` script:
```bash
./run.sh
```
This script will:
- Stop and remove any existing container named `notify-mcp-container`.
- Start a new Docker container from the `michielroos/notify-mcp` image.
- The server inside the container will listen on the port specified by the `PORT` environment variable (defaults to 3000), mapped to the same port on your host.

#### Docker: Custom UID/GID and D-Bus for Notifications (via `run.sh`)

-   **Runtime UID/GID**: The `run.sh` script allows you to run the application inside the Docker container with a specific UID and GID. By default, it uses your current host user's UID/GID (if detectable via `id -u`/`id -g`) or falls back to 1000. You can customize this by setting `APP_UID` and `APP_GID` environment variables *before* running `run.sh`:
    ```bash
    APP_UID=1001 APP_GID=1001 ./run.sh
    ```
-   **D-Bus for Desktop Notifications from Container**: For the containerized server to send desktop notifications to your host system, the `run.sh` script mounts your host's D-Bus socket (typically `$XDG_RUNTIME_DIR/bus`) into the container. It also sets the necessary environment variables (`DBUS_SESSION_BUS_ADDRESS`, `XDG_RUNTIME_DIR`) inside the container for the application to find and use this socket. This allows `notify-rust` (and underlying libraries) to communicate with your host's notification daemon.
    -   **Security Note**: Mounting the D-Bus socket reduces container isolation. While necessary for this feature, be aware that a compromised container could potentially interact with other D-Bus services on your host. Use with caution, especially if the container image source is not fully trusted or in multi-user environments.

## Usage 📋

This server can be used with any MCP client that supports SSE transport, such as:

- GitHub Copilot in VS Code
- Claude desktop app (if it supports custom MCP SSE servers)
- Custom MCP clients

### Adding the Server to VS Code

1.  Open VS Code (with GitHub Copilot or a similar MCP-enabled extension).
2.  Run the command: `MCP: Add server` (or the equivalent for your extension).
3.  Choose "HTTP (Server-sent events)" as the transport.
4.  Enter the server URL. If running locally (native or Docker via `build.sh` default): `http://127.0.0.1:3000/sse` (or your custom port if `PORT` env var was set).
5.  Start the server from the MCP panel in VS Code.

### Example Usage

Once connected, you can instruct your MCP client to use the `notify` tool:

```
@mcp notify title="Hello from MCP" message="This notification came via the server!"
```
Or in a more conversational way with an agent:
```
Send a notification with the title "Reminder" and the message "Meeting in 5 minutes."
```

## Available Tools 🛠️

### Notify Tool (`notify`)

Sends a desktop notification with a custom title and message.

**Parameters:**
-   `title` (string): The title of the notification.
-   `message` (string): The body text of the notification.

## Development 👨‍💻

This project uses the `rust-mcp-sdk` for the MCP server implementation and `notify-rust` for desktop notification capabilities.

-   **Adding Tools**: Define new tools in `src/tools.rs` (structs, `#[mcp_tool]` macro, `call_tool` logic) and add them to the `tool_box!` enum.
-   **Handler Logic**: Update the handler in `src/handler.rs` if new tools require different parameter handling or if new MCP message types need custom processing.
-   **Server Configuration**: Adjust server settings (port, host, capabilities) in `src/main.rs`.
-   **Testing**: Run tests with `cargo test`. Add new tests for new functionality.

## License 📄

This project is licensed under the MIT License - see the `LICENSE` file for details (if one is created, otherwise assume MIT or specify).

## Acknowledgments 🙏

-   [rust-mcp-sdk](https://github.com/rust-mcp-stack/rust-mcp-sdk) for the MCP SDK.
-   [notify-rust](https://github.com/hoodie/notify-rust) for the notification capabilities. 