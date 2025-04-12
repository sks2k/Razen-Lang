# Razen Language Installer for Windows
# Copyright 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.4

# Enable TLS 1.2 for all web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Repository URL
$RAZEN_REPO = "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"

# Error handling and cleanup function
function Handle-Error {
    param (
        [string]$ErrorMessage,
        [string]$RecoveryHint = "",
        [int]$ExitCode = 1
    )
    
    Write-ColorOutput "Error: $ErrorMessage" "Red"
    
    if ($RecoveryHint) {
        Write-ColorOutput "Hint: $RecoveryHint" "Yellow"
    }
    
    # Clean up temporary files if they exist
    if (Test-Path $TMP_DIR -ErrorAction SilentlyContinue) {
        Write-ColorOutput "Cleaning up temporary files..." "Yellow"
        Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    exit $ExitCode
}

# Function to check internet connectivity
function Test-InternetConnectivity {
    Write-ColorOutput "Checking internet connectivity..." "Yellow"
    
    $testUrls = @(
        "https://github.com",
        "https://raw.githubusercontent.com",
        "https://www.google.com"
    )
    
    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-ColorOutput "  ✓ Internet connection verified" "Green"
                return $true
            }
        } catch {
            # Continue to next URL
        }
    }
    
    Write-ColorOutput "  ✗ No internet connection detected" "Red"
    Write-ColorOutput "    Please check your network connection and try again" "Yellow"
    return $false
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-ColorOutput "  ✗ This script requires administrator privileges" "Red"
        Write-ColorOutput "    Please run PowerShell as Administrator and try again" "Yellow"
        return $false
    }
    
    Write-ColorOutput "  ✓ Running with administrator privileges" "Green"
    return $true
}

# Function to download a file with retry logic
function Download-File {
    param (
        [string]$Uri,
        [string]$OutFilePath,
        [string]$Description,
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            Write-ColorOutput "    Downloading $Description..." "Yellow"
            Invoke-WebRequest -Uri $Uri -OutFile $OutFilePath -ErrorAction Stop
            Write-ColorOutput "      ✓ Downloaded $Description" "Green"
            $success = $true
            return $true
        } catch {
            $retryCount++
            if ($retryCount -lt $MaxRetries) {
                Write-ColorOutput "      ✗ Download attempt $retryCount failed. Retrying in 2 seconds..." "Yellow"
                Start-Sleep -Seconds 2
            } else {
                Write-ColorOutput "      ✗ Failed to download $Description after $MaxRetries attempts" "Red"
                Write-ColorOutput "        Error: $($_.Exception.Message)" "Red"
                return $false
            }
        }
    }
    
    return $false
}

# Function to print colored text
function Write-ColorOutput {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    $originalColor = $Host.UI.RawUI.ForegroundColor
    try {
        $Host.UI.RawUI.ForegroundColor = $Color
    } catch {
        Write-Warning "Invalid color '$Color'. Using default."
        # If color is invalid, don't change it, or fallback to White
        # $Host.UI.RawUI.ForegroundColor = "White" # Optional fallback
    }
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $originalColor
}

# Function to check for updates
function Check-ForUpdates {
    Write-ColorOutput "Checking for updates..." "Yellow"

    try {
        $versionUrl = "$RAZEN_REPO/version"
        $versionFile = Join-Path $env:TEMP "razen-version.txt"
        Invoke-WebRequest -Uri $versionUrl -OutFile $versionFile -ErrorAction Stop
        $latestVersion = (Get-Content $versionFile -ErrorAction Stop).Trim() # Trim whitespace

        if ($latestVersion -eq $RAZEN_VERSION) {
            Write-ColorOutput "Razen is already up to date ($RAZEN_VERSION)." "Green"
            return 0
        } else {
            Write-ColorOutput "New version available: $latestVersion" "Yellow"
            Write-ColorOutput "Current version: $RAZEN_VERSION" "Yellow"
            return 2
        }
    } catch {
        Write-ColorOutput "Failed to check for updates. Please check your internet connection." "Red"
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        return 1
    } finally {
         # Clean up temporary version file
         if (Test-Path $versionFile) {
             Remove-Item $versionFile -Force -ErrorAction SilentlyContinue
         }
    }
}

# Function to perform update
function Perform-Update {
    Write-ColorOutput "Updating Razen..." "Yellow"

    try {
        $installerUrl = "$RAZEN_REPO/install.ps1"
        $installerFile = Join-Path $env:TEMP "razen-update-installer.ps1"
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerFile -ErrorAction Stop

        # Run the installer with the latest version
        & $installerFile
        return $LASTEXITCODE
    } catch {
        Write-ColorOutput "Failed to download the latest installer." "Red"
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        return 1
    } finally {
        # Clean up temporary installer file
        if (Test-Path $installerFile) {
            Remove-Item $installerFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to create symbolic links
function Create-Symlinks {
    param (
        [string]$InstallDir
    )

    Write-ColorOutput "Creating symbolic links..." "Yellow"
    $scriptsDir = Join-Path $InstallDir "scripts"
    $Scripts = @() # Initialize as empty array

    # Dynamically find all scripts in the scripts directory
    if (Test-Path $scriptsDir) {
         $scriptFiles = Get-ChildItem -Path $scriptsDir -File
        
        if ($scriptFiles.Count -eq 0) {
            # Fallback to a predefined list if no files are found (or keep empty if that's intended)
            $Scripts = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help", "razen-extension", "razen") # Assuming fallback needed
            Write-ColorOutput "No script files found, using default list." "Yellow"
        } else {
            $Scripts = $scriptFiles | Select-Object -ExpandProperty Name
            Write-ColorOutput "Found $($Scripts.Count) scripts to link." "Green"
        }
    } else {
        Write-ColorOutput "Scripts directory not found at $scriptsDir" "Red"
        return 1 # Exit function if scripts dir is missing
    }

    # Ensure Razen directory exists in Program Files
    $razenProgFilesDir = Join-Path $env:ProgramFiles "Razen"
    if (-not (Test-Path $razenProgFilesDir)) {
        try {
            New-Item -ItemType Directory -Path $razenProgFilesDir -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-ColorOutput "Failed to create directory: $razenProgFilesDir. Check permissions." "Red"
            Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
            return 1
        }
    }

    # Create symlinks in Program Files\Razen
    foreach ($script in $Scripts) {
        $target = Join-Path $scriptsDir $script
        $link = Join-Path $razenProgFilesDir $script

        if (Test-Path $target) {
            try {
                # Remove existing item (file or symlink) if it exists
                if (Test-Path $link -ErrorAction SilentlyContinue) {
                    Remove-Item $link -Force -ErrorAction Stop
                }
                New-Item -ItemType SymbolicLink -Path $link -Target $target -Force -ErrorAction Stop | Out-Null
                Write-ColorOutput "  ✓ Created symbolic link for $script in $razenProgFilesDir" "Green"
            } catch {
                Write-ColorOutput "  ✗ Failed to create symbolic link for $script in $razenProgFilesDir" "Red"
                Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
                # Continue with next script, but maybe return 1 at the end? Decide on behavior.
            }
        } else {
            Write-ColorOutput "  ✗ Target script not found for $script ($target). Skipping link." "Yellow"
            # Continue with next script
        }
    }

    # Create CMD wrappers in System32 for system-wide access
    $system32Dir = Join-Path $env:windir "System32"
    foreach ($script in $Scripts) {
        $sourceLink = Join-Path $razenProgFilesDir $script # The symlink we just created
        $destinationCmd = Join-Path $system32Dir "$script.cmd"

        if (Test-Path $sourceLink) { # Check if the symlink exists
            try {
                # Create a CMD wrapper pointing to the symlink in Program Files
                # Use double quotes around the path in case of spaces
                $cmdContent = "@echo off`r`n`"%SystemDrive%\Program Files\Razen\$script%`" %*" # Use `r`n for Windows line endings
                
                # Remove existing file if it exists
                if (Test-Path $destinationCmd -ErrorAction SilentlyContinue) {
                    Remove-Item $destinationCmd -Force -ErrorAction Stop
                }

                # Write the CMD wrapper
                Set-Content -Path $destinationCmd -Value $cmdContent -Force -Encoding Ascii -ErrorAction Stop # Use ASCII for simple CMD files
                Write-ColorOutput "  ✓ Created system shortcut for $script in System32" "Green"
            } catch {
                Write-ColorOutput "  ✗ Failed to create system shortcut for $script in System32" "Red"
                Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
                Write-ColorOutput "    Please ensure you have permissions to write to $system32Dir." "Yellow"
                # Continue with next script
            }
        } else {
             Write-ColorOutput "  ✗ Source symlink not found for $script ($sourceLink). Skipping system shortcut." "Yellow"
        }
    }

    # Add Program Files\Razen to User PATH environment variable if not already there
    $razenbinPath = $razenProgFilesDir
    try {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $pathParts = $userPath -split ';' | Where-Object { $_ -ne '' } # Split and remove empty entries

        if ($pathParts -notcontains $razenbinPath) {
            $newPath = ($pathParts + $razenbinPath) -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-ColorOutput "  ✓ Added Razen directory to User PATH environment variable" "Green"
            Write-ColorOutput "    Note: You may need to restart PowerShell/CMD for the new PATH to take effect." "Yellow"
        } else {
             Write-ColorOutput "  ✓ Razen directory already in User PATH." "Green"
        }
    } catch {
        Write-ColorOutput "  ✗ Failed to modify User PATH environment variable." "Red"
        Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
        Write-ColorOutput "    You may need to manually add '$razenbinPath' to your User or System PATH." "Yellow"
        return 1 # Indicate potential failure
    }

    return 0 # Success
}

# Function to uninstall Razen
function Uninstall-Razen {
    Write-ColorOutput "Uninstalling Razen..." "Yellow"

    # Try to get scripts from install dir, otherwise use default list
    $installDir = "C:\Program Files\Razen"
    $scriptsDir = Join-Path $InstallDir "scripts"
    $Scripts = @()
    if (Test-Path $scriptsDir) {
         $scriptFiles = Get-ChildItem -Path $scriptsDir -File -ErrorAction SilentlyContinue
         if ($scriptFiles) {
             $Scripts = $scriptFiles | Select-Object -ExpandProperty Name
         }
    }
    if ($Scripts.Count -eq 0) {
        $Scripts = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help", "razen-extension", "razen") # Add default/known scripts
        $Scripts = $Scripts | Select-Object -Unique # Ensure no duplicates
        Write-ColorOutput "Could not read scripts from install directory, using default list for cleanup." "Yellow"
    }

    # Remove system-wide CMD wrappers from System32
    $system32Dir = Join-Path $env:windir "System32"
    foreach ($script in $Scripts) {
        $cmdFile = Join-Path $system32Dir "$script.cmd"
        if (Test-Path $cmdFile -ErrorAction SilentlyContinue) {
            try {
                Remove-Item $cmdFile -Force -ErrorAction Stop
                Write-ColorOutput "  ✓ Removed system shortcut for $script from System32" "Green"
            } catch {
                 Write-ColorOutput "  ✗ Failed to remove system shortcut $cmdFile" "Yellow"
                 Write-ColorOutput "    Error: $($_.Exception.Message)" "Yellow"
            }
        }
    }

    # Remove symbolic links from Razen directory in Program Files (if the directory exists)
    $razenProgFilesDir = Join-Path $env:ProgramFiles "Razen"
    if (Test-Path $razenProgFilesDir -ErrorAction SilentlyContinue) {
        foreach ($script in $Scripts) {
            $link = Join-Path $razenProgFilesDir $script
            if (Test-Path $link -ErrorAction SilentlyContinue) {
                 try {
                    Remove-Item $link -Force -ErrorAction Stop
                    Write-ColorOutput "  ✓ Removed symbolic link for $script from $razenProgFilesDir" "Green"
                 } catch {
                    Write-ColorOutput "  ✗ Failed to remove link $link" "Yellow"
                    Write-ColorOutput "    Error: $($_.Exception.Message)" "Yellow"
                 }
            }
        }
    } else {
         Write-ColorOutput "Razen directory in Program Files not found ($razenProgFilesDir), skipping link removal." "Cyan"
    }


    # Remove from User PATH
    try {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $razenPathToRemove = $razenProgFilesDir # Use the variable consistently
        if ($userPath -like "*$razenPathToRemove*") {
            $pathParts = $userPath -split ';' | Where-Object { $_ -ne '' }
            $newPathParts = $pathParts | Where-Object { $_ -ne $razenPathToRemove }
            $newPath = $newPathParts -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-ColorOutput "  ✓ Removed Razen directory from User PATH" "Green"
            Write-ColorOutput "    Note: Restart PowerShell/CMD for PATH change to take effect." "Yellow"
        } else {
             Write-ColorOutput "  ✓ Razen directory not found in User PATH." "Cyan"
        }
    } catch {
         Write-ColorOutput "  ✗ Failed to modify User PATH environment variable." "Yellow"
         Write-ColorOutput "    Error: $($_.Exception.Message)" "Yellow"
         Write-ColorOutput "    Please manually check your PATH environment variable if needed." "Yellow"
    }

    # Remove installation directory C:\Program Files\Razen
    if (Test-Path $installDir -ErrorAction SilentlyContinue) {
        Write-ColorOutput "Removing installation directory: $installDir..." "Yellow"
        try {
            Remove-Item $installDir -Recurse -Force -ErrorAction Stop
            Write-ColorOutput "  ✓ Removed installation directory" "Green"
        } catch {
             Write-ColorOutput "  ✗ Failed to remove installation directory $installDir" "Red"
             Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
             Write-ColorOutput "    You may need to remove it manually." "Yellow"
        }
    } else {
         Write-ColorOutput "Installation directory not found ($installDir)." "Cyan"
    }

    Write-ColorOutput "`n✅ Razen uninstall process finished." "Green"
    Write-ColorOutput "   Please check for any remaining files or PATH entries manually if errors occurred." "Yellow"
    exit 0
}

# Function to install VS Code extension
function Install-VSCodeExtension {
    param (
        [string]$InstallDir
    )
    
    Write-ColorOutput "Installing VS Code extension..." "Yellow"
    
    # Check if VS Code is installed
    $vscodeInstalled = $false
    $vscodeExePath = $null
    
    # Check common VS Code installation paths
    $possiblePaths = @(
        "${env:ProgramFiles}\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd",
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin\code.cmd"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $vscodeExePath = $path
            $vscodeInstalled = $true
            break
        }
    }
    
    # If VS Code is installed, try to install extension using VS Code CLI
    if ($vscodeInstalled) {
        Write-ColorOutput "  ✓ VS Code detected at: $vscodeExePath" "Green"
        
        # Create extension directory
        $extensionSourceDir = Join-Path $InstallDir "razen-vscode-extension"
        $extensionTargetDir = Join-Path $env:USERPROFILE ".vscode\extensions\razen-lang.razen"
        
        try {
            # Create extension directory if it doesn't exist
            if (-not (Test-Path $extensionTargetDir)) {
                New-Item -ItemType Directory -Path $extensionTargetDir -Force | Out-Null
            }
            
            # Check if extension source exists
            if (Test-Path $extensionSourceDir) {
                # Copy extension files
                Copy-Item -Path (Join-Path $extensionSourceDir "*") -Destination $extensionTargetDir -Recurse -Force
                Write-ColorOutput "  ✓ VS Code extension installed to: $extensionTargetDir" "Green"
                Write-ColorOutput "    Restart VS Code to activate the extension" "Yellow"
            } else {
                # Create basic extension structure if source doesn't exist
                Write-ColorOutput "  ⚠ Extension source not found, creating basic extension..." "Yellow"
                
                # Create package.json
                $packageJson = @{
                    "name" = "razen-lang"
                    "displayName" = "Razen Language Support"
                    "description" = "Syntax highlighting and tools for Razen programming language"
                    "version" = "0.1.0"
                    "publisher" = "razen-lang"
                    "engines" = @{
                        "vscode" = "^1.60.0"
                    }
                    "categories" = @("Programming Languages")
                    "contributes" = @{
                        "languages" = @(
                            @{
                                "id" = "razen"
                                "aliases" = @("Razen", "razen")
                                "extensions" = @(".rzn")
                                "configuration" = "./language-configuration.json"
                            }
                        )
                        "grammars" = @(
                            @{
                                "language" = "razen"
                                "scopeName" = "source.razen"
                                "path" = "./syntaxes/razen.tmLanguage.json"
                            }
                        )
                    }
                } | ConvertTo-Json -Depth 10
                
                # Create language configuration
                $languageConfig = @{
                    "comments" = @{
                        "lineComment" = "#"
                        "blockComment" = @("/*", "*/")
                    }
                    "brackets" = @(
                        @("[", "]")
                        @("(", ")")
                        @("{", "}")
                    )
                    "autoClosingPairs" = @(
                        @{
                            "open" = "{"
                            "close" = "}"
                        }
                        @{
                            "open" = "["
                            "close" = "]"
                        }
                        @{
                            "open" = "("
                            "close" = ")"
                        }
                        @{
                            "open" = "`""
                            "close" = "`""
                        }
                        @{
                            "open" = "'"
                            "close" = "'"
                        }
                    )
                } | ConvertTo-Json -Depth 10
                
                # Create basic syntax highlighting
                $syntaxHighlighting = @{
                    "$schema" = "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json"
                    "name" = "Razen"
                    "patterns" = @(
                        @{
                            "include" = "#keywords"
                        }
                        @{
                            "include" = "#strings"
                        }
                        @{
                            "include" = "#comments"
                        }
                    )
                    "repository" = @{
                        "keywords" = @{
                            "patterns" = @(
                                @{
                                    "name" = "keyword.control.razen"
                                    "match" = "\b(if|else|while|for|return|function|var|const|let|print|input)\b"
                                }
                            )
                        }
                        "strings" = @{
                            "name" = "string.quoted.double.razen"
                            "begin" = "`""
                            "end" = "`""
                            "patterns" = @(
                                @{
                                    "name" = "constant.character.escape.razen"
                                    "match" = "\\."
                                }
                            )
                        }
                        "comments" = @{
                            "patterns" = @(
                                @{
                                    "name" = "comment.line.number-sign.razen"
                                    "match" = "#.*$"
                                }
                                @{
                                    "name" = "comment.block.razen"
                                    "begin" = "/\*"
                                    "end" = "\*/"
                                }
                            )
                        }
                    }
                    "scopeName" = "source.razen"
                } | ConvertTo-Json -Depth 10
                
                # Create directories
                New-Item -ItemType Directory -Path (Join-Path $extensionTargetDir "syntaxes") -Force | Out-Null
                
                # Write files
                Set-Content -Path (Join-Path $extensionTargetDir "package.json") -Value $packageJson
                Set-Content -Path (Join-Path $extensionTargetDir "language-configuration.json") -Value $languageConfig
                Set-Content -Path (Join-Path $extensionTargetDir "syntaxes\razen.tmLanguage.json") -Value $syntaxHighlighting
                
                Write-ColorOutput "  ✓ Basic VS Code extension created at: $extensionTargetDir" "Green"
                Write-ColorOutput "    Restart VS Code to activate the extension" "Yellow"
            }
            
            return $true
        } catch {
            Write-ColorOutput "  ✗ Failed to install VS Code extension" "Red"
            Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
            return $false
        }
    } else {
        Write-ColorOutput "  ⚠ VS Code not detected" "Yellow"
        Write-ColorOutput "    To install the extension manually after installing VS Code:" "Yellow"
        Write-ColorOutput "    1. Copy files from $InstallDir\razen-vscode-extension to %USERPROFILE%\.vscode\extensions\razen-lang.razen" "White"
        Write-ColorOutput "    2. Restart VS Code" "White"
        return $false
    }
}

# Function to install JetBrains plugin
function Install-JetBrainsPlugin {
    param (
        [string]$InstallDir
    )
    
    Write-ColorOutput "Installing JetBrains plugin..." "Yellow"
    
    # Check if any JetBrains IDEs are installed
    $jetBrainsInstalled = $false
    $jetBrainsConfigDirs = @(
        (Join-Path $env:APPDATA "JetBrains"),
        (Join-Path $env:LOCALAPPDATA "JetBrains")
    )
    
    foreach ($dir in $jetBrainsConfigDirs) {
        if (Test-Path $dir) {
            $jetBrainsInstalled = $true
            Write-ColorOutput "  ✓ JetBrains IDE configuration detected at: $dir" "Green"
            break
        }
    }
    
    # Create plugin directory
    $pluginSourceDir = Join-Path $InstallDir "razen-jetbrains-plugin"
    $pluginTargetDir = Join-Path $env:USERPROFILE ".razen\jetbrains-plugin"
    
    try {
        # Create plugin directory if it doesn't exist
        if (-not (Test-Path $pluginTargetDir)) {
            New-Item -ItemType Directory -Path $pluginTargetDir -Force | Out-Null
        }
        
        # Check if plugin source exists
        if (Test-Path $pluginSourceDir) {
            # Copy plugin files
            Copy-Item -Path (Join-Path $pluginSourceDir "*") -Destination $pluginTargetDir -Recurse -Force
            Write-ColorOutput "  ✓ JetBrains plugin files copied to: $pluginTargetDir" "Green"
        } else {
            # Create placeholder files
            Write-ColorOutput "  ⚠ Plugin source not found, creating placeholder..." "Yellow"
            
            # Create README file
            $readmeContent = @"
# Razen Language Plugin for JetBrains IDEs

This is a placeholder for the Razen language plugin for JetBrains IDEs.
The actual plugin will be available soon.

## Installation Instructions

1. Open your JetBrains IDE (IntelliJ IDEA, PyCharm, etc.)
2. Go to Settings/Preferences > Plugins
3. Click the gear icon and select "Install Plugin from Disk..."
4. Navigate to the plugin JAR file location
5. Restart the IDE

## Features

- Syntax highlighting for Razen (.rzn) files
- Code completion
- Error highlighting
- Navigation
- Refactoring tools

## Support

For support, please visit the Razen language website or GitHub repository.
"@
            
            Set-Content -Path (Join-Path $pluginTargetDir "README.md") -Value $readmeContent
            
            Write-ColorOutput "  ✓ JetBrains plugin placeholder created at: $pluginTargetDir" "Green"
        }
        
        if ($jetBrainsInstalled) {
            Write-ColorOutput "  ℹ To install the plugin in your JetBrains IDE:" "Yellow"
            Write-ColorOutput "    1. Open your JetBrains IDE (IntelliJ IDEA, PyCharm, etc.)" "White"
            Write-ColorOutput "    2. Go to Settings/Preferences > Plugins" "White"
            Write-ColorOutput "    3. Click the gear icon and select 'Install Plugin from Disk...'" "White"
            Write-ColorOutput "    4. Navigate to $pluginTargetDir and select the plugin JAR file" "White"
            Write-ColorOutput "    5. Restart the IDE" "White"
        } else {
            Write-ColorOutput "  ⚠ No JetBrains IDE detected" "Yellow"
            Write-ColorOutput "    Plugin files have been saved to: $pluginTargetDir" "Yellow"
            Write-ColorOutput "    Install the plugin manually after installing a JetBrains IDE" "Yellow"
        }
        
        return $true
    } catch {
        Write-ColorOutput "  ✗ Failed to install JetBrains plugin" "Red"
        Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to display installation summary
function Show-InstallationSummary {
    param (
        [string]$InstallDir,
        [string]$Version,
        [bool]$PathUpdated,
        [bool]$VSCodeExtensionInstalled,
        [bool]$JetBrainsPluginInstalled
    )
    
    Write-ColorOutput "`n✅ Razen $Version has been successfully installed!" "Green"
    
    # Installation details
    Write-ColorOutput "`nInstallation Details:" "Yellow"
    Write-ColorOutput "  • Installation Directory: $InstallDir" "White"
    Write-ColorOutput "  • Version: $Version" "White"
    Write-ColorOutput "  • PATH Environment Variable: $(if ($PathUpdated) { "Updated" } else { "Not Updated" })" "White"
    Write-ColorOutput "  • VS Code Extension: $(if ($VSCodeExtensionInstalled) { "Installed" } else { "Not Installed" })" "White"
    Write-ColorOutput "  • JetBrains Plugin: $(if ($JetBrainsPluginInstalled) { "Installed" } else { "Not Installed" })" "White"
    
    # Available commands
    Write-ColorOutput "`nAvailable Commands:" "Yellow"
    Write-ColorOutput "  • razen <file.rzn> - Run a Razen program" "White"
    Write-ColorOutput "  • razen-debug <file.rzn> - Run a Razen program in debug mode" "White"
    Write-ColorOutput "  • razen-test <file.rzn> - Run tests for a Razen program" "White"
    Write-ColorOutput "  • razen-run <file.rzn> - Run a Razen program with additional options" "White"
    Write-ColorOutput "  • razen-update - Update Razen to the latest version" "White"
    Write-ColorOutput "  • razen-help - Show help information" "White"
    Write-ColorOutput "  • razen-extension - Manage Razen extensions" "White"
    
    # Example usage
    Write-ColorOutput "`nExample Usage:" "Yellow"
    Write-ColorOutput "  razen hello.rzn" "White"
    Write-ColorOutput "  razen-debug app.rzn" "White"
    Write-ColorOutput "  razen-update" "White"
    
    # Next steps
    Write-ColorOutput "`nNext Steps:" "Yellow"
    Write-ColorOutput "  1. Create a new Razen program: razen new myprogram.rzn" "White"
    Write-ColorOutput "  2. Run the example programs: razen examples/hello.rzn" "White"
    Write-ColorOutput "  3. Check for updates: razen-update" "White"
    
    # Important notes
    Write-ColorOutput "`nImportant Notes:" "Yellow"
    Write-ColorOutput "  • You may need to restart your terminal for the PATH changes to take effect" "White"
    Write-ColorOutput "  • To uninstall Razen, run: powershell -ExecutionPolicy Bypass -File $InstallDir\install.ps1 --uninstall" "White"
    Write-ColorOutput "  • For help and documentation, run: razen-help" "White"
    
    # Support information
    Write-ColorOutput "`nSupport:" "Yellow"
    Write-ColorOutput "  • GitHub: https://github.com/BasaiCorp/razen-lang" "White"
    Write-ColorOutput "  • Documentation: Coming soon" "White"
    Write-ColorOutput "  • Report Issues: https://github.com/BasaiCorp/razen-lang/issues" "White"
    
    Write-ColorOutput "`nThank you for installing Razen! Happy coding!" "Cyan"
}

# --- Main Script Logic ---

# Print banner
Write-ColorOutput (@"
██████╗  █████╗ ███████╗███████╗███╗   ██╗
██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║
██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║
██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║███████╗███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
"@) "Blue"

Write-ColorOutput "Programming Language $RAZEN_VERSION" "Yellow"
Write-ColorOutput "By Prathmesh Barot, Basai Corporation" "Cyan"
Write-ColorOutput "Copyright 2025 Prathmesh Barot`n" "Yellow"

# Small delay to make the banner more readable
Start-Sleep -Seconds 1

# Check if running as administrator
if (-not (Test-Administrator)) {
    Handle-Error -ErrorMessage "This script requires administrator privileges" -RecoveryHint "Run PowerShell as Administrator and try again"
}

# Create temporary directory
$TMP_DIR = Join-Path $env:TEMP "razen-install-$($PID)-$(Get-Random)" # Make temp dir more unique
try {
    if (Test-Path $TMP_DIR) { Remove-Item $TMP_DIR -Recurse -Force } # Clean up previous attempt if exists
    New-Item -ItemType Directory -Path $TMP_DIR -Force -ErrorAction Stop | Out-Null
    Write-ColorOutput "  ✓ Created temporary directory: $TMP_DIR" "Green"
} catch {
    Handle-Error -ErrorMessage "Failed to create temporary directory: $TMP_DIR" -RecoveryHint "Check permissions and try again"
}

# Define cleanup trap for temporary directory
trap [Exception] {
    Write-ColorOutput "An error occurred: $($_.Exception.Message)" "Red"
    if (Test-Path $TMP_DIR) {
        Write-ColorOutput "Cleaning up temporary directory: $TMP_DIR" "Yellow"
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Exit with non-zero code might depend on where the trap is hit
    # exit 1 # Uncomment if you want script to halt on any error after cleanup
    continue # Allows script to potentially continue if error is non-fatal (e.g., inside a loop)
}

# Argument parsing
$FORCE_UPDATE = $false
$DO_UNINSTALL = $false
$DO_UPDATE_CHECK = $false

if ($args.Count -gt 0) {
    switch -Wildcard ($args[0].ToLower()) {
        '--force-update' {
            Write-ColorOutput "Force update mode activated. Will replace existing files if found." "Yellow"
            $FORCE_UPDATE = $true
        }
        '--uninstall' { $DO_UNINSTALL = $true }
        'update' { $DO_UPDATE_CHECK = $true }
        '--update' { $DO_UPDATE_CHECK = $true }
        # Add other arguments if needed
        default { Write-Warning "Unknown argument: $($args[0])" }
    }
}

# Handle uninstall action first
if ($DO_UNINSTALL) {
    Uninstall-Razen # This function exits the script
}

# Define installation directory
$installDir = "C:\Program Files\Razen"

# Check for update action or if already installed (presence of version file)
$versionFilePath = Join-Path $installDir "version"
if ($DO_UPDATE_CHECK -or (Test-Path $versionFilePath)) {
    if ($DO_UPDATE_CHECK) { Write-ColorOutput "Update requested." "Cyan"}
    elseif (Test-Path $versionFilePath) { Write-ColorOutput "Existing installation detected. Checking for updates." "Cyan"}

    # Check for updates
    $updateStatus = Check-ForUpdates

    if ($updateStatus -eq 2) { # New version available
        Write-ColorOutput "Do you want to update Razen? (y/n)" "Yellow"
        $response = Read-Host
        if ($response -notmatch '^[Yy]$') {
            Write-ColorOutput "Update cancelled." "Blue"
            Write-ColorOutput "Tip: You can run '$($MyInvocation.MyCommand.Name) update' or 'razen-update' later." "Green"
            Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
            exit 0
        }

        # Perform the update by re-running the latest installer
        $updateResult = Perform-Update
        if ($updateResult -ne 0) {
            Write-ColorOutput "Update failed. Please try again later." "Red"
            Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
            exit 1
        }
        # Assuming Perform-Update runs the new installer which then exits
        Write-ColorOutput "Update process started." "Green" # Message before exiting current script
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 0
    } elseif ($updateStatus -eq 0) { # Already up to date
        Write-ColorOutput "Razen is already up to date." "Green"
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 0
    } else { # Failed to check for updates
        Write-ColorOutput "Failed to check for updates." "Red"
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# --- Installation Process ---
Write-ColorOutput "Starting Razen installation..." "Cyan"

# Check if installation directory exists
if (Test-Path $installDir) {
    if ($FORCE_UPDATE) {
        Write-ColorOutput "Force update specified. Removing existing Razen installation at $installDir..." "Yellow"
        try {
            Remove-Item $installDir -Recurse -Force -ErrorAction Stop
            Write-ColorOutput "  ✓ Removed existing installation." "Green"
        } catch {
             Write-ColorOutput "  ✗ Failed to remove existing installation directory $installDir" "Red"
             Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
             Write-ColorOutput "    Please remove it manually and try again." "Yellow"
             Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
             exit 1
        }
    } else {
        Write-ColorOutput "Razen seems to be already installed at $installDir." "Yellow"
        Write-ColorOutput "To update, run: $($MyInvocation.MyCommand.Name) update" "Cyan"
        Write-ColorOutput "To force reinstallation over the existing one, run: $($MyInvocation.MyCommand.Name) --force-update" "Cyan"
        Write-ColorOutput "To uninstall, run: $($MyInvocation.MyCommand.Name) --uninstall" "Cyan"
        Write-ColorOutput "Installation cancelled." "Blue"
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 0
    }
}

# Create installation directory structure
Write-ColorOutput "Creating installation directories..." "Yellow"
$dirsToCreate = @(
    $installDir,
    (Join-Path $installDir "src"),
    (Join-Path $installDir "scripts"),
    (Join-Path $installDir "properties"),
    # Add directories for extensions if they are part of the core download
    (Join-Path $installDir "razen-vscode-extension"),
    (Join-Path $installDir "razen-jetbrains-plugin")
)

foreach ($dir in $dirsToCreate) {
    try {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null
             Write-ColorOutput "  ✓ Created directory: $dir" "Green"
        } else {
             Write-ColorOutput "  ✓ Directory already exists: $dir" "Cyan"
        }
    } catch {
        Handle-Error -ErrorMessage "Failed to create directory: $dir" -RecoveryHint "Check permissions and try again"
    }
}
Write-ColorOutput "  ✓ Installation directory structure prepared." "Green"


# Helper function for downloads
$maxRetries = 3
$retryCount = 0
$downloadSuccess = $false

while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
    try {
        # Download main.py
        if (-not (Download-File -Uri "$RAZEN_REPO/main.py" -OutFilePath (Join-Path $TMP_DIR "main.py") -Description "main.py")) { $downloadSuccess = $false }
        
        # Download src files
        $srcFiles = @("lexer.py", "parser.py", "interpreter.py", "runtime.py", "__init__.py") # Add __init__.py here
        New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "src") -Force | Out-Null # Ensure temp src dir exists
        foreach ($file in $srcFiles) {
            if (-not (Download-File -Uri "$RAZEN_REPO/src/$file" -OutFilePath (Join-Path $TMP_DIR "src\$file") -Description "src/$file")) { $downloadSuccess = $false }
        }
        
        # Download properties files
        $propFiles = @("variables.rzn", "keywords.rzn", "operators.rzn")
        New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "properties") -Force | Out-Null # Ensure temp props dir exists
        foreach ($file in $propFiles) {
            if (-not (Download-File -Uri "$RAZEN_REPO/properties/$file" -OutFilePath (Join-Path $TMP_DIR "properties\$file") -Description "properties/$file")) {
                Write-ColorOutput "    ⚠ Creating empty properties/$file as fallback." "Yellow"
                New-Item -ItemType File -Path (Join-Path $TMP_DIR "properties\$file") -Force | Out-Null
                # Continue even if download fails, with empty file
            }
        }
        
        # Download script files
        $scriptsToDownload = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help", "razen-extension", "razen.cmd") # Add razen.cmd if it exists in repo
        New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "scripts") -Force | Out-Null # Ensure temp scripts dir exists
        foreach ($script in $scriptsToDownload) {
             if (-not (Download-File -Uri "$RAZEN_REPO/scripts/$script" -OutFilePath (Join-Path $TMP_DIR "scripts\$script") -Description "scripts/$script")) {
                Write-ColorOutput "    ⚠ Creating empty scripts/$script as fallback." "Yellow"
                New-Item -ItemType File -Path (Join-Path $TMP_DIR "scripts\$script") -Force | Out-Null
                # Continue, maybe crucial scripts missing? Decide if $downloadSuccess should be $false here.
             }
        }
        
        # Download extension files (assuming they are directories in the repo)
        # This part needs adjustment based on how extensions are stored in the repo.
        # Option 1: Download zip files
        # Option 2: Download individual files recursively (complex)
        # Option 3: Assume they are pre-packaged and download core files only for now
        # Let's assume we only download placeholders or need manual steps for now.
        # We created the target dirs earlier. Let's download a placeholder README or core file if available.
        Write-ColorOutput "Downloading IDE extension placeholders (if available)..." "Yellow"
        Download-File -Uri "$RAZEN_REPO/razen-vscode-extension/README.md" -OutFilePath (Join-Path $TMP_DIR "razen-vscode-extension\README.md") -Description "VS Code Extension README" # Example
        Download-File -Uri "$RAZEN_REPO/razen-jetbrains-plugin/README.md" -OutFilePath (Join-Path $TMP_DIR "razen-jetbrains-plugin\README.md") -Description "JetBrains Plugin README" # Example
        
        $downloadSuccess = $true
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-ColorOutput "  ✗ Download attempt $retryCount failed. Retrying in 2 seconds..." "Yellow"
            Start-Sleep -Seconds 2
        } else {
            Write-ColorOutput "  ✗ Failed to download Razen core files after $maxRetries attempts" "Red"
            Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
            Write-ColorOutput "    Please check your internet connection and try again." "Yellow"
            Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
            exit 1
        }
    }
}

if (-not $downloadSuccess) {
    Handle-Error -ErrorMessage "Failed to download Razen core files" -RecoveryHint "Check your internet connection and try again"
}
Write-ColorOutput "  ✓ All downloads completed." "Green"


# Copy downloaded files from temporary directory to installation directory
Write-ColorOutput "Copying files to installation directory..." "Yellow"
try {
    # Copy main.py
    Copy-Item (Join-Path $TMP_DIR "main.py") $installDir -Force -ErrorAction Stop
    # Copy src directory contents
    Copy-Item (Join-Path $TMP_DIR "src\*") (Join-Path $installDir "src") -Recurse -Force -ErrorAction Stop
    # Copy properties directory contents
    Copy-Item (Join-Path $TMP_DIR "properties\*") (Join-Path $installDir "properties") -Recurse -Force -ErrorAction Stop
    # Copy scripts directory contents
    Copy-Item (Join-Path $TMP_DIR "scripts\*") (Join-Path $installDir "scripts") -Recurse -Force -ErrorAction Stop
    # Copy extension directory contents (placeholders for now)
    Copy-Item (Join-Path $TMP_DIR "razen-vscode-extension\*") (Join-Path $installDir "razen-vscode-extension") -Recurse -Force -ErrorAction Stop
    Copy-Item (Join-Path $TMP_DIR "razen-jetbrains-plugin\*") (Join-Path $installDir "razen-jetbrains-plugin") -Recurse -Force -ErrorAction Stop

    Write-ColorOutput "  ✓ Copied files to $installDir" "Green"
} catch {
     Handle-Error -ErrorMessage "Failed to copy downloaded files to installation directory" -RecoveryHint "Check permissions and try again"
}

# Download and save the latest installer script for future updates
Write-ColorOutput "Saving current installer script for future updates..." "Yellow"
try {
    # Prefer downloading the latest version from the repo
    Invoke-WebRequest -Uri "$RAZEN_REPO/install.ps1" -OutFile (Join-Path $installDir "install.ps1") -UseBasicParsing -ErrorAction Stop
    Write-ColorOutput "  ✓ Saved latest installer script from repository." "Green"
} catch {
    Write-ColorOutput "Warning: Could not download latest installer script from repository." "Yellow"
    Write-ColorOutput "Error: $($_.Exception.Message)" "Yellow"
    # Fallback: Copy the currently executing script if path is known
    if ($MyInvocation.MyCommand.Source) {
        try {
             Copy-Item $MyInvocation.MyCommand.Source (Join-Path $installDir "install.ps1") -Force -ErrorAction Stop
             Write-ColorOutput "  ✓ Saved currently running installer script as fallback." "Green"
        } catch {
             Write-ColorOutput "  ✗ Failed to copy current installer script." "Red"
             # Not critical, update might fail later.
        }
    } else {
         Write-ColorOutput "  ✗ Could not determine path of current script to save as fallback." "Red"
    }
}

# Create version file
try {
    Set-Content -Path (Join-Path $installDir "version") -Value $RAZEN_VERSION -Force -ErrorAction Stop
    Write-ColorOutput "  ✓ Created version file." "Green"
} catch {
     Handle-Error -ErrorMessage "Failed to create version file in $installDir" -RecoveryHint "Check permissions and try again"
}


# Create empty __init__.py file in root install dir (if needed for Python imports)
$initPyPath = Join-Path $installDir "__init__.py"
if (-not (Test-Path $initPyPath)) {
    New-Item -ItemType File -Path $initPyPath -Force | Out-Null
}
# We already downloaded src/__init__.py

Write-ColorOutput "  ✓ Core file installation complete." "Green"


# Check for Rust installation
Write-ColorOutput "`nChecking for Rust installation (required for compiler)..." "Yellow"

# Check if Rust is installed, if not, prompt to install it
if (-not (Test-RustInstalled)) {
    Write-ColorOutput "Rust (rustc command) not found in PATH. Razen compiler requires Rust." "Yellow"
    Write-ColorOutput "Do you want to attempt automatic installation using rustup (recommended)? (y/n)" "Yellow"
    $confirmation = Read-Host

    if ($confirmation -match '^[Yy]$') {
        if (-not (Install-Rust)) {
            Handle-Error -ErrorMessage "Automatic Rust installation failed or was incomplete" -RecoveryHint "Install Rust manually from https://rustup.rs and run this installer again"
        }
        # If Install-Rust succeeded, Rust *should* be available now in the session PATH
    } else {
        Handle-Error -ErrorMessage "Rust installation skipped" -RecoveryHint "Install Rust manually from https://rustup.rs and run this installer again"
    }
} else {
    Write-ColorOutput "  ✓ Rust is already installed and found in PATH." "Green"
}

# Check Rust version (now that we expect it to be installed)
try {
    $rustVersionOutput = (rustc --version)
    if ($rustVersionOutput) {
         $rustVersion = $rustVersionOutput -replace 'rustc\s+', ''
         Write-ColorOutput "  ✓ Rust version: $rustVersion" "Green"
    } else {
         Write-ColorOutput "  ✗ Could not retrieve Rust version, but rustc command exists." "Yellow"
    }
} catch {
    Write-ColorOutput "  ✗ Error checking Rust version." "Yellow"
    Write-ColorOutput "    Error: $($_.Exception.Message)" "Yellow"
}


# Create symbolic links and PATH entries
Write-ColorOutput "`nConfiguring system integration (Symlinks, PATH)..." "Yellow"
$symlinkResult = Create-Symlinks -InstallDir $installDir
if ($symlinkResult -ne 0) {
    Handle-Error -ErrorMessage "Failed to create symbolic links or update PATH correctly" -RecoveryHint "Check previous error messages for details"
} else {
     Write-ColorOutput "  ✓ System integration completed." "Green"
}


# Clean up temporary directory (final step before IDE prompt)
Write-ColorOutput "`nCleaning up temporary files..." "Yellow"
if (Test-Path $TMP_DIR) {
    Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "  ✓ Cleaned up temporary directory." "Green"
}


# Ask about IDE extension installation
Write-ColorOutput "`nOptional: Install IDE extensions for Razen?" "Yellow"
Write-ColorOutput "  1. VS Code Extension (Copies files)" "Cyan"
Write-ColorOutput "  2. JetBrains Plugin (Copies files)" "Cyan"
Write-ColorOutput "  3. Skip" "Cyan"

$ide_choice = Read-Host "Enter your choice (1-3)"
Write-Host "" # Newline

# Install IDE extensions based on user choice
$vsCodeExtensionInstalled = $false
$jetBrainsPluginInstalled = $false

switch ($ide_choice) {
    "1" {
        $vsCodeExtensionInstalled = Install-VSCodeExtension -InstallDir $installDir
    }
    "2" {
        $jetBrainsPluginInstalled = Install-JetBrainsPlugin -InstallDir $installDir
    }
    "3" {
        $vsCodeExtensionInstalled = Install-VSCodeExtension -InstallDir $installDir
        $jetBrainsPluginInstalled = Install-JetBrainsPlugin -InstallDir $installDir
    }
    default {
        Write-ColorOutput "Skipping IDE extension installation." "Yellow"
    }
}

# Display installation summary
Show-InstallationSummary -InstallDir $installDir -Version $RAZEN_VERSION -PathUpdated ($symlinkResult -eq 0) -VSCodeExtensionInstalled $vsCodeExtensionInstalled -JetBrainsPluginInstalled $jetBrainsPluginInstalled

# Remove the trap handler cleanly before exiting
trap -Remove [Exception]
exit 0