use async_trait::async_trait;
use rust_mcp_schema::{
    schema_utils::CallToolError, CallToolRequest, CallToolResult, ListToolsRequest,
    ListToolsResult, RpcError,
};
use rust_mcp_sdk::{mcp_server::ServerHandler, McpServer};

use crate::tools::NotificationTools;

// Custom Handler to handle MCP Messages
pub struct NotifyServerHandler;

#[async_trait]
#[allow(unused)]
impl ServerHandler for NotifyServerHandler {
    // Handle ListToolsRequest, return list of available tools as ListToolsResult
    async fn handle_list_tools_request(
        &self,
        _request: ListToolsRequest,
        _runtime: &dyn McpServer,
    ) -> std::result::Result<ListToolsResult, RpcError> {
        Ok(ListToolsResult {
            meta: None,
            next_cursor: None,
            tools: NotificationTools::tools(),
        })
    }

    /// Handles incoming CallToolRequest and processes it using the appropriate tool.
    async fn handle_call_tool_request(
        &self,
        request: CallToolRequest,
        _runtime: &dyn McpServer,
    ) -> std::result::Result<CallToolResult, CallToolError> {
        // Attempt to convert request parameters into NotificationTools enum
        let tool_params: NotificationTools =
            NotificationTools::try_from(request.params).map_err(CallToolError::new)?;

        // Match the tool variant and execute its corresponding logic
        match tool_params {
            NotificationTools::NotifyTool(notify_tool) => notify_tool.call_tool(),
        }
    }

    async fn on_server_started(&self, runtime: &dyn McpServer) {
        tracing::info!("Notification MCP Server started!");
    }
} 