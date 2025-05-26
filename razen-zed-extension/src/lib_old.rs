use zed_extension_api as zed;

struct RazenExtension {
    cached_settings: Option<RazenLanguageServerSettings>,
}

#[derive(Clone)]
struct RazenLanguageServerSettings {
    enable_completions: bool,
    enable_hover: bool,
    enable_diagnostics: bool,
    library_path: String,
    stdlib_path: String,
    interpreter_path: String,
    debug_mode: bool,
}

impl Default for RazenLanguageServerSettings {
    fn default() -> Self {
        Self {
            enable_completions: true,
            enable_hover: true,
            enable_diagnostics: true,
            library_path: "./libs".to_string(),
            stdlib_path: "/usr/local/lib/razen/stdlib".to_string(),
            interpreter_path: "razen".to_string(),
            debug_mode: false,
        }
    }
}

impl RazenExtension {
    fn language_server_command(
        &mut self,
        _language_server_id: &zed::LanguageServerId,
        _worktree: &zed::Worktree,
    ) -> Result<zed::Command, String> {
        let settings = self.cached_settings.get_or_insert_with(Default::default);
        
        Ok(zed::Command {
            command: settings.interpreter_path.clone(),
            args: vec!["--lsp".to_string()],
            env: Default::default(),
        })
    }

    fn language_server_initialization_options(
        &mut self,
        _language_server_id: &zed::LanguageServerId,
        _worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>, String> {
        let settings = self.cached_settings.get_or_insert_with(Default::default);
        
        let initialization_options = serde_json::json!({
            "enable_snippets": true,
            "enable_completion": settings.enable_completions,
            "enable_hover": settings.enable_hover,
            "enable_diagnostics": settings.enable_diagnostics,
            "library_path": settings.library_path,
            "stdlib_path": settings.stdlib_path,
            "interpreter_path": settings.interpreter_path,
            "debug_mode": settings.debug_mode,
            "completion_trigger_characters": [".", "[", "(", " ", "+", "=", "\"", "'", ",", ":"],
            "signature_help_trigger_characters": ["(", ","]
        });

        Ok(Some(initialization_options))
    }

    fn language_server_workspace_configuration(
        &mut self,
        _language_server_id: &zed::LanguageServerId,
        _worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>, String> {
        let settings = self.cached_settings.get_or_insert_with(Default::default);
        
        let workspace_config = serde_json::json!({
            "razen": {
                "enable": true,
                "trace": {
                    "server": if settings.debug_mode { "verbose" } else { "off" }
                },
                "completion": {
                    "enable": settings.enable_completions
                },
                "hover": {
                    "enable": settings.enable_hover
                },
                "diagnostics": {
                    "enable": settings.enable_diagnostics
                },
                "libraries": {
                    "path": settings.library_path,
                    "stdlib": settings.stdlib_path
                },
                "interpreter": {
                    "path": settings.interpreter_path
                }
            }
        });

        Ok(Some(workspace_config))
    }

    fn label_for_completion(
        &self,
        _language_server_id: &zed::LanguageServerId,
        completion: zed::lsp::Completion,
    ) -> Option<zed::CodeLabel> {
        match completion.kind? {
            zed::lsp::CompletionKind::Function => {
                let name = &completion.label;
                Some(zed::CodeLabel {
                    code: format!("fun {}()", name),
                    spans: vec![
                        zed::CodeLabelSpan::code_range(0..3),
                        zed::CodeLabelSpan::literal(format!(" {}", name), None),
                        zed::CodeLabelSpan::code_range((4 + name.len())..(6 + name.len())),
                    ],
                    filter_range: (4..(4 + name.len())).into(),
                })
            }
            zed::lsp::CompletionKind::Variable => {
                let name = &completion.label;
                let var_type = completion.detail.as_deref().unwrap_or("any");
                Some(zed::CodeLabel {
                    code: format!("{}: {}", name, var_type),
                    spans: vec![
                        zed::CodeLabelSpan::literal(name.clone(), None),
                        zed::CodeLabelSpan::code_range((name.len() + 1)..(name.len() + 3 + var_type.len())),
                    ],
                    filter_range: (0..name.len()).into(),
                })
            }
            zed::lsp::CompletionKind::Keyword => {
                let name = &completion.label;
                Some(zed::CodeLabel {
                    code: name.clone(),
                    spans: vec![zed::CodeLabelSpan::code_range(0..name.len())],
                    filter_range: (0..name.len()).into(),
                })
            }
            zed::lsp::CompletionKind::Module => {
                let name = &completion.label;
                Some(zed::CodeLabel {
                    code: format!("lib {};", name),
                    spans: vec![
                        zed::CodeLabelSpan::code_range(0..3),
                        zed::CodeLabelSpan::literal(format!(" {}", name), None),
                        zed::CodeLabelSpan::code_range((4 + name.len())..(5 + name.len())),
                    ],
                    filter_range: (4..(4 + name.len())).into(),
                })
            }
            _ => None,
        }
    }

    fn label_for_symbol(
        &self,
        _language_server_id: &zed::LanguageServerId,
        symbol: zed::lsp::Symbol,
    ) -> Option<zed::CodeLabel> {
        match symbol.kind {
            zed::lsp::SymbolKind::Function => {
                let name = &symbol.name;
                Some(zed::CodeLabel {
                    code: format!("fun {}()", name),
                    spans: vec![
                        zed::CodeLabelSpan::code_range(0..3),
                        zed::CodeLabelSpan::literal(format!(" {}", name), None),
                        zed::CodeLabelSpan::code_range((4 + name.len())..(6 + name.len())),
                    ],
                    filter_range: (4..(4 + name.len())).into(),
                })
            }
            zed::lsp::SymbolKind::Variable => {
                let name = &symbol.name;
                Some(zed::CodeLabel {
                    code: format!("let {}", name),
                    spans: vec![
                        zed::CodeLabelSpan::code_range(0..3),
                        zed::CodeLabelSpan::literal(format!(" {}", name), None),
                    ],
                    filter_range: (4..(4 + name.len())).into(),
                })
            }
            zed::lsp::SymbolKind::Class => {
                let name = &symbol.name;
                Some(zed::CodeLabel {
                    code: format!("class {}", name),
                    spans: vec![
                        zed::CodeLabelSpan::code_range(0..5),
                        zed::CodeLabelSpan::literal(format!(" {}", name), None),
                    ],
                    filter_range: (6..(6 + name.len())).into(),
                })
            }
            _ => None,
        }
    }
}

impl zed::Extension for RazenExtension {
    fn new() -> Self {
        Self {
            cached_settings: None,
        }
    }

    fn language_server_command(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command, String> {
        self.language_server_command(language_server_id, worktree)
    }

    fn language_server_initialization_options(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>, String> {
        self.language_server_initialization_options(language_server_id, worktree)
    }

    fn language_server_workspace_configuration(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>, String> {
        self.language_server_workspace_configuration(language_server_id, worktree)
    }

    fn label_for_completion(
        &self,
        language_server_id: &zed::LanguageServerId,
        completion: zed::lsp::Completion,
    ) -> Option<zed::CodeLabel> {
        self.label_for_completion(language_server_id, completion)
    }

    fn label_for_symbol(
        &self,
        language_server_id: &zed::LanguageServerId,
        symbol: zed::lsp::Symbol,
    ) -> Option<zed::CodeLabel> {
        self.label_for_symbol(language_server_id, symbol)
    }
}

zed::register_extension!(RazenExtension);