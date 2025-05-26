const path = require('path');
const { workspace, ExtensionContext } = require('vscode');

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

  // Start the client. This will also launch the server
  client.start();
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
