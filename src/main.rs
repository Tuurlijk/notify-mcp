mod handler;
mod tools;

use std::time::Duration;

use rust_mcp_sdk::mcp_server::{HyperServerOptions, hyper_server};

use handler::NotifyServerHandler;
use rust_mcp_schema::{
    Implementation, InitializeResult, LATEST_PROTOCOL_VERSION, ServerCapabilities,
    ServerCapabilitiesTools,
};

use rust_mcp_sdk::error::SdkResult;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> SdkResult<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "notify_mcp=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // STEP 1: Define server details and capabilities
    let server_details = InitializeResult {
        // Server name and version
        server_info: Implementation {
            name: "Notify MCP Server".to_string(),
            version: "0.1.0".to_string(),
        },
        capabilities: ServerCapabilities {
            // Indicates that server supports MCP tools
            tools: Some(ServerCapabilitiesTools { list_changed: None }),
            ..Default::default() // Using default values for other fields
        },
        meta: None,
        instructions: Some("MCP server for sending desktop notifications".to_string()),
        protocol_version: LATEST_PROTOCOL_VERSION.to_string(),
    };

    // STEP 2: Instantiate our custom handler for handling MCP messages
    let handler = NotifyServerHandler {};

    // Determine port from environment variable or use default
    let port = std::env::var("PORT")
        .ok()
        .and_then(|port_str| {
            port_str
                .parse::<u16>()
                .map_err(|e| {
                    tracing::error!(
                        port = %port_str,
                        error = %e,
                        "Invalid PORT environment variable. Defaulting to 3000."
                    );
                })
                .ok()
        })
        .unwrap_or(3000);

    // STEP 3: Instantiate HyperServer with server_details, handler, and options
    let server = hyper_server::create_server(
        server_details,
        handler,
        HyperServerOptions {
            host: "0.0.0.0".to_string(),
            port: port,
            ping_interval: Duration::from_secs(15),
            ..Default::default()
        },
    );

    // STEP 4: Start the server
    tracing::info!("Starting Notify MCP Server on http://127.0.0.1:{}...", port);
    server.start().await?;

    Ok(())
}
