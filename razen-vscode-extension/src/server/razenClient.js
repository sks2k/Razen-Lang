const path = require('path');
const { workspace, ExtensionContext, window, commands, languages, SemanticTokensLegend } = require('vscode');

const {
  LanguageClient,
  TransportKind
} = require('vscode-languageclient/node');

let client;

function activateLanguageServer(context) {
  // The server is implemented in node
  const serverModule = context.asAbsolutePath(
    path.join('src', 'server', 'razenServer.js')
  );
  
  // The debug options for the server
  // --inspect=6009: runs the server in Node's Inspector mode so VS Code can attach to the server for debugging
  const debugOptions = { execArgv: ['--nolazy', '--inspect=6009'] };

  // If the extension is launched in debug mode then the debug server options are used
  // Otherwise the run options are used
  const serverOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: debugOptions
    }
  };

  // Options to control the language client
  const clientOptions = {
    // Register the server for Razen documents
    documentSelector: [{ scheme: 'file', language: 'razen' }],
    synchronize: {
      // Notify the server about file changes to '.clientrc files contained in the workspace
      fileEvents: workspace.createFileSystemWatcher('**/.clientrc')
    }
  };

  // Create the language client and start the client.
  client = new LanguageClient(
    'razenLanguageServer',
    'Razen Language Server',
    serverOptions,
    clientOptions
  );

  // Define semantic token types and modifiers for variable and library usage highlighting
  const tokenTypes = ['variable', 'library'];
  const tokenModifiers = ['declaration', 'unused', 'used'];
  const legend = new SemanticTokensLegend(tokenTypes, tokenModifiers);
  
  // Register semantic token provider through the client
  const tokenProvider = languages.registerDocumentSemanticTokensProvider(
    { language: 'razen' },
    {
      provideDocumentSemanticTokens: (_) => {
        // The actual tokens are provided by the server
        return null;
      }
    },
    legend
  );
  
  // Add the token provider to subscriptions
  context.subscriptions.push(tokenProvider);
  
  // Start the client. This will also launch the server
  client.start();
  
  // Add custom CSS to style semantic tokens
  const workspaceConfig = workspace.getConfiguration();
  workspaceConfig.update('editor.semanticTokenColorCustomizations', {
    enabled: true,
    rules: {
      'variable.declaration.unused': {
        foreground: '#75715E', // Dull color for unused variables
        fontStyle: 'italic'
      },
      'variable.declaration.used': {
        foreground: '#F8F8F2', // Bright color for used variables
        fontStyle: 'bold'
      },
      'variable.used': {
        foreground: '#F8F8F2', // Bright color for variable usages
      },
      'library.declaration.unused': {
        foreground: '#7E7E7E', // Dull color for unused libraries
        fontStyle: 'italic'
      },
      'library.declaration.used': {
        foreground: '#66D9EF', // Bright blue color for used libraries
        fontStyle: 'bold'
      },
      'library.used': {
        foreground: '#66D9EF', // Bright blue color for library usages
      }
    }
  }, true);
}

function deactivateLanguageServer() {
  if (!client) {
    return undefined;
  }
  return client.stop();
}

module.exports = {
  activateLanguageServer,
  deactivateLanguageServer
};
