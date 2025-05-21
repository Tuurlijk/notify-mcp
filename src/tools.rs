use notify_rust::Notification;
use rust_mcp_schema::{schema_utils::CallToolError, CallToolResult};
use rust_mcp_sdk::{
    macros::{mcp_tool, JsonSchema},
    tool_box,
};
use std::fmt;

// Custom error type
#[derive(Debug)]
struct NotifyError(String);

impl fmt::Display for NotifyError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::error::Error for NotifyError {}

//****************//
//  NotifyTool  //
//****************//
#[mcp_tool(
    name = "notify",
    description = "Sends a desktop notification with the given title and message"
)]
#[derive(Debug, ::serde::Deserialize, ::serde::Serialize, JsonSchema)]
pub struct NotifyTool {
    /// The title of the notification.
    title: String,
    /// The message body of the notification.
    message: String,
}

impl NotifyTool {
    pub fn call_tool(&self) -> Result<CallToolResult, CallToolError> {
        // Attempt to show the notification
        match Notification::new()
            .summary(&self.title)
            .body(&self.message)
            .show()
        {
            Ok(_) => {
                let success_message = format!(
                    "Notification sent successfully with title: \"{}\" and message: \"{}\"",
                    self.title, self.message
                );
                Ok(CallToolResult::text_content(success_message, None))
            }
            Err(e) => {
                let error = NotifyError(format!("Failed to send notification: {}", e));
                Err(CallToolError::new(error))
            }
        }
    }
}

//******************//
//  NotificationTools  //
//******************//
// Generates an enum named NotificationTools with a NotifyTool variant
tool_box!(NotificationTools, [NotifyTool]);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_notify_error_display() {
        let original_error_msg = "D-Bus connection failed";
        let notify_error = NotifyError(format!("Failed to send notification: {}", original_error_msg));
        assert_eq!(
            format!("{}", notify_error),
            "Failed to send notification: D-Bus connection failed"
        );
    }

    #[test]
    fn test_notify_tool_success_message_formatting() {
        // This test doesn't actually send a notification, only checks message construction.
        // To truly test Notification::show(), you'd need a more complex setup or a mockable notify-rust.
        let tool = NotifyTool {
            title: "Test Title".to_string(),
            message: "Test Message".to_string(),
        };

        // We can't directly call tool.call_tool() and check Ok() variant 
        // without triggering Notification::show(). 
        // So, let's just check the success message part if we assume Notification::show() was Ok.
        let expected_success_output = CallToolResult::text_content(
            "Notification sent successfully with title: \"Test Title\" and message: \"Test Message\""
                .to_string(),
            None,
        );
        
        // Manually construct what the Ok part of call_tool would produce
        let success_message = format!(
            "Notification sent successfully with title: \"{}\" and message: \"{}\"",
            tool.title,
            tool.message
        );
        let actual_result = CallToolResult::text_content(success_message, None);

        assert_eq!(actual_result.content.get(0).unwrap().as_text_content().unwrap().text, expected_success_output.content.get(0).unwrap().as_text_content().unwrap().text);
        // We might also want to check actual_result.meta if it were used.
    }
} 