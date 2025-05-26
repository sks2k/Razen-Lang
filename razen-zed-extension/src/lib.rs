use zed_extension_api as zed;
use zed::{Result, Extension};

/// RazenExtension provides language support for the Razen programming language
pub struct RazenExtension {
    // Extension state can be added here if needed
}

impl Extension for RazenExtension {
    fn new() -> Self {
        Self {}
    }

    fn language_server_command(
        &self,
        _language_server_id: &str,
        _language: &str,
        _worktree_root: &std::path::Path,
    ) -> Result<Option<zed::LanguageServerCommand>> {
        // This will be implemented when a language server is available for Razen
        Ok(None)
    }

    fn language_server_initialization_options(
        &self,
        _language_server_id: &str,
        _language: &str,
    ) -> Result<Option<serde_json::Value>> {
        // This will be implemented when a language server is available for Razen
        Ok(None)
    }
}

zed::register_extension!(RazenExtension);