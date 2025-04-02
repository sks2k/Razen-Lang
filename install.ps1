# Razen Language Installer for Windows
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.4

# Enable TLS 1.2 for all web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Repository URL
$RAZEN_REPO = "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"

# Get version from the version file
if (Test-Path "version") {
    $RAZEN_VERSION = Get-Content "version" -Raw
} else {
    # Download version file if not present
    try {
        Invoke-WebRequest -Uri "$RAZEN_REPO/version" -OutFile "version" -ErrorAction Stop
        $RAZEN_VERSION = Get-Content "version" -Raw
    } catch {
        Write-ColorOutput "Failed to download version information. Using default version." "Red"
        $RAZEN_VERSION = "beta v0.1.4"
    }
}

# Remove any trailing whitespace or newlines
$RAZEN_VERSION = $RAZEN_VERSION.Trim()

# Function to print colored text
function Write-ColorOutput {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    $originalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
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
        $latestVersion = Get-Content $versionFile -ErrorAction Stop
        
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
        Write-ColorOutput "Error: $_" "Red"
        return 1
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
        Write-ColorOutput "Error: $_" "Red"
        return 1
    }
}

# Function to create symbolic links
function Create-Symlinks {
    param (
        [string]$InstallDir
    )
    
    Write-ColorOutput "Creating symbolic links..." "Yellow"
    $scriptsDir = Join-Path $InstallDir "scripts"
    
    # Dynamically find all scripts in the scripts directory
    if (Test-Path $scriptsDir) {
        $scriptFiles = Get-ChildItem -Path $scriptsDir -File
        
        if ($scriptFiles.Count -eq 0) {
            # Fallback to a predefined list if no files are found
            $Scripts = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help")
            Write-ColorOutput "No script files found, using default list." "Yellow"
        } else {
            $Scripts = $scriptFiles | Select-Object -ExpandProperty Name
            Write-ColorOutput "Found $($Scripts.Count) scripts to link." "Green"
        }
    } else {
        Write-ColorOutput "Scripts directory not found at $scriptsDir" "Red"
        return 1
    }
    
    # Ensure Razen directory exists in Program Files
    if (-not (Test-Path "$env:ProgramFiles\Razen")) {
        New-Item -ItemType Directory -Path "$env:ProgramFiles\Razen" -Force | Out-Null
    }
    
    foreach ($script in $Scripts) {
        $target = Join-Path $scriptsDir $script
        $link = Join-Path $env:ProgramFiles "Razen\$script"
        
        if (Test-Path $target) {
            try {
                # Remove existing symlink if it exists
                if (Test-Path $link) {
                    Remove-Item $link -Force
                }
                New-Item -ItemType SymbolicLink -Path $link -Target $target -Force | Out-Null
                Write-ColorOutput "  ✓ Created symbolic link for $script" "Green"
            } catch {
                Write-ColorOutput "  ✗ Failed to create symbolic link for $script" "Red"
                Write-ColorOutput "    Error: $_" "Red"
                return 1
            }
        } else {
            Write-ColorOutput "  ✗ Failed to create symbolic link for $script (file not found)" "Red"
            return 1
        }
    }
    
    # Create symlinks in Windows directory for system-wide access (similar to /usr/bin on Linux)
    foreach ($script in $Scripts) {
        $source = Join-Path $env:ProgramFiles "Razen\$script"
        $destination = Join-Path $env:windir "System32\$script.cmd"
        
        if (Test-Path $source) {
            try {
                # Create a CMD wrapper for each script
                $cmdContent = "@echo off`nC:\Program Files\Razen\$script %*"
                
                # Remove existing file if it exists
                if (Test-Path $destination) {
                    Remove-Item $destination -Force
                }
                
                # Write the CMD wrapper
                Set-Content -Path $destination -Value $cmdContent -Force
                Write-ColorOutput "  ✓ Created system shortcut for $script" "Green"
            } catch {
                Write-ColorOutput "  ✗ Failed to create system shortcut for $script" "Red"
                Write-ColorOutput "    Error: $_" "Red"
                return 1
            }
        }
    }
    
    # Add to PATH environment variable if not already there
    $razenbinPath = "$env:ProgramFiles\Razen"
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if (-not ($userPath -like "*$razenbinPath*")) {
        try {
            [Environment]::SetEnvironmentVariable("Path", "$userPath;$razenbinPath", "User")
            Write-ColorOutput "  ✓ Added Razen to PATH environment variable" "Green"
        } catch {
            Write-ColorOutput "  ✗ Failed to add Razen to PATH" "Yellow"
            Write-ColorOutput "    You may need to manually add $razenbinPath to your PATH" "Yellow"
        }
    }
    
    return 0
}

# Function to uninstall Razen
function Uninstall-Razen {
    Write-ColorOutput "Uninstalling Razen..." "Yellow"
    
    $scripts = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help", "razen-extension")
    $installDir = "C:\Program Files\Razen"
    
    # Remove symbolic links from Razen directory
    foreach ($script in $scripts) {
        $link = Join-Path $env:ProgramFiles "Razen\$script"
        if (Test-Path $link) {
            Remove-Item $link -Force
            Write-ColorOutput "  ✓ Removed symbolic link for $script" "Green"
        }
    }
    
    # Remove system-wide CMD wrappers
    foreach ($script in $scripts) {
        $cmdFile = Join-Path $env:windir "System32\$script.cmd"
        if (Test-Path $cmdFile) {
            Remove-Item $cmdFile -Force
            Write-ColorOutput "  ✓ Removed system shortcut for $script" "Green"
        }
    }
    
    # Remove installation directory
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
        Write-ColorOutput "  ✓ Removed installation directory" "Green"
    }
    
    # Remove from PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -like "*$installDir*") {
        $newPath = $userPath.Replace(";$installDir", "")
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-ColorOutput "  ✓ Removed from PATH" "Green"
    }
    
    Write-ColorOutput "`n✅ Razen has been successfully uninstalled!" "Green"
    exit 0
}

# Print banner
Write-ColorOutput @"
██████╗  █████╗ ███████╗███████╗███╗   ██╗
██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║
██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║
██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║███████╗███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
"@ "Blue"

Write-ColorOutput "Programming Language $RAZEN_VERSION" "Yellow"
Write-ColorOutput "By Prathmesh Barot, Basai Corporation" "Cyan"
Write-ColorOutput "Copyright © 2025 Prathmesh Barot`n" "Yellow"

# Small delay to make the banner more readable
Start-Sleep -Seconds 1

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ColorOutput "This script requires administrator privileges." "Red"
    Write-ColorOutput "Please run PowerShell as administrator and try again." "Yellow"
    Write-ColorOutput "`nTo run as administrator:" "Yellow"
    Write-ColorOutput "1. Right-click on PowerShell" "Green"
    Write-ColorOutput "2. Select 'Run as administrator'" "Green"
    Write-ColorOutput "3. Navigate to your installation directory" "Green"
    Write-ColorOutput "4. Run the installer again" "Green"
    exit 1
}

# Create temporary directory
$TMP_DIR = Join-Path $env:TEMP "razen-install-$(Get-Random)"
if (-not (New-Item -ItemType Directory -Path $TMP_DIR -Force)) {
    Write-ColorOutput "Failed to create temporary directory" "Red"
    exit 1
}
Write-ColorOutput "  ✓ Created temporary directory" "Green"

# Check for force update flag
$FORCE_UPDATE = $false
if ($args[0] -eq "--force-update") {
    Write-ColorOutput "Force update mode activated. Will replace all existing files." "Yellow"
    $FORCE_UPDATE = $true
}

# Check for uninstall flag
if ($args[0] -eq "--uninstall") {
    Uninstall-Razen
}

# Create installation directory
$installDir = "C:\Program Files\Razen"

# Check for update flag or if already installed
if ($args[0] -eq "update" -or $args[0] -eq "--update" -or (Test-Path (Join-Path $installDir "version"))) {
    # Check for updates
    $updateStatus = Check-ForUpdates
    
    if ($updateStatus -eq 2) {
        Write-ColorOutput "Do you want to update Razen? (y/n)" "Yellow"
        $response = Read-Host
        if ($response -notmatch '^[Yy]$') {
            Write-ColorOutput "Update cancelled." "Blue"
            Write-ColorOutput "Tip: You can use 'razen-update' to update Razen later." "Green"
            Remove-Item $TMP_DIR -Recurse -Force
            exit 0
        }
        
        # Perform the update
        $updateResult = Perform-Update
        if ($updateResult -ne 0) {
            Write-ColorOutput "Update failed. Please try again later." "Red"
            Remove-Item $TMP_DIR -Recurse -Force
            exit 1
        }
        exit 0
    } elseif ($updateStatus -eq 0) {
        Write-ColorOutput "Razen is already up to date." "Green"
        Remove-Item $TMP_DIR -Recurse -Force
        exit 0
    } else {
        Write-ColorOutput "Failed to check for updates." "Red"
        Remove-Item $TMP_DIR -Recurse -Force
        exit 1
    }
}

# Check if installation directory exists
if (Test-Path $installDir) {
    if ($FORCE_UPDATE) {
        Write-ColorOutput "Removing existing Razen installation..." "Yellow"
        Remove-Item $installDir -Recurse -Force
    } else {
        Write-ColorOutput "Razen is already installed." "Yellow"
        Write-ColorOutput "New Razen commands are available with this version." "Yellow"
        Write-ColorOutput "Do you want to update Razen? (y/n)" "Yellow"
        $response = Read-Host
        if ($response -notmatch '^[Yy]$') {
            Write-ColorOutput "Installation cancelled." "Blue"
            Write-ColorOutput "Tip: You can use 'razen-update' to update Razen later." "Green"
            Remove-Item $TMP_DIR -Recurse -Force
            exit 0
        }
        Write-ColorOutput "Updating Razen..." "Yellow"
        Remove-Item $installDir -Recurse -Force
    }
}

# Create installation directory structure
$dirs = @(
    $installDir,
    (Join-Path $installDir "src"),
    (Join-Path $installDir "scripts"),
    (Join-Path $installDir "properties")
)

foreach ($dir in $dirs) {
    if (-not (New-Item -ItemType Directory -Path $dir -Force)) {
        Write-ColorOutput "Failed to create directory: $dir" "Red"
        Remove-Item $TMP_DIR -Recurse -Force
        exit 1
    }
}
Write-ColorOutput "  ✓ Created installation directory" "Green"

# Download Razen files
Write-ColorOutput "Downloading Razen files..." "Yellow"

# Download main.py
try {
    Invoke-WebRequest -Uri "$RAZEN_REPO/main.py" -OutFile (Join-Path $TMP_DIR "main.py") -ErrorAction Stop
    Write-ColorOutput "  ✓ Downloaded main.py" "Green"
} catch {
    Write-ColorOutput "Failed to download main.py" "Red"
    Remove-Item $TMP_DIR -Recurse -Force
    exit 1
}

# Download src files
$srcFiles = @("lexer.py", "parser.py", "interpreter.py", "runtime.py")
foreach ($file in $srcFiles) {
    try {
        Invoke-WebRequest -Uri "$RAZEN_REPO/src/$file" -OutFile (Join-Path $TMP_DIR "src\$file") -ErrorAction Stop
        Write-ColorOutput "  ✓ Downloaded src/$file" "Green"
    } catch {
        Write-ColorOutput "Failed to download src/$file" "Red"
        Remove-Item $TMP_DIR -Recurse -Force
        exit 1
    }
}

# Download properties files
$propFiles = @("variables.rzn", "keywords.rzn", "operators.rzn")
foreach ($file in $propFiles) {
    try {
        Invoke-WebRequest -Uri "$RAZEN_REPO/properties/$file" -OutFile (Join-Path $TMP_DIR "properties\$file") -ErrorAction Stop
        Write-ColorOutput "  ✓ Downloaded properties/$file" "Green"
    } catch {
        # Create empty file if download fails
        New-Item -ItemType File -Path (Join-Path $TMP_DIR "properties\$file") -Force | Out-Null
        Write-ColorOutput "  ⚠ Created empty properties/$file" "Yellow"
    }
}

# Download script files
$scripts = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help")
foreach ($script in $scripts) {
    try {
        Invoke-WebRequest -Uri "$RAZEN_REPO/scripts/$script" -OutFile (Join-Path $TMP_DIR "scripts\$script") -ErrorAction Stop
        Write-ColorOutput "  ✓ Downloaded scripts/$script" "Green"
    } catch {
        # Create empty file if download fails
        New-Item -ItemType File -Path (Join-Path $TMP_DIR "scripts\$script") -Force | Out-Null
        Write-ColorOutput "  ⚠ Created empty scripts/$script" "Yellow"
    }
}

# Copy files to installation directory
Write-ColorOutput "Copying files to installation directory..." "Yellow"

# Copy main.py
Copy-Item (Join-Path $TMP_DIR "main.py") $installDir -Force

# Copy src files
Copy-Item (Join-Path $TMP_DIR "src\*.py") (Join-Path $installDir "src") -Force

# Copy properties files
Copy-Item (Join-Path $TMP_DIR "properties\*.rzn") (Join-Path $installDir "properties") -Force

# Copy script files
Copy-Item (Join-Path $TMP_DIR "scripts\*") (Join-Path $installDir "scripts") -Force

# Download and save the latest installer script for future updates
try {
    Invoke-WebRequest -Uri "$RAZEN_REPO/install.ps1" -OutFile (Join-Path $installDir "install.ps1") -ErrorAction Stop
    Write-ColorOutput "  ✓ Saved latest installer script for future updates" "Green"
} catch {
    Write-ColorOutput "Warning: Could not download latest installer script. Using current version instead." "Yellow"
    if (Test-Path $PSCommandPath) {
        Copy-Item $PSCommandPath (Join-Path $installDir "install.ps1") -Force
    }
}

# Create version file
$RAZEN_VERSION | Out-File (Join-Path $installDir "version") -Force

# Create empty __init__.py files
New-Item -ItemType File -Path (Join-Path $installDir "__init__.py") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $installDir "src\__init__.py") -Force | Out-Null

Write-ColorOutput "  ✓ Copied files to installation directory" "Green"

# Check for Rust installation
Write-ColorOutput "Checking for Rust installation..." "Yellow"

# Function to check if Rust is installed
function Test-RustInstalled {
    try {
        $rustcVersion = (& rustc --version 2>$null)
        return $rustcVersion -ne $null
    } catch {
        return $false
    }
}

# Function to install Rust
function Install-Rust {
    Write-ColorOutput "Downloading and installing Rust..." "Yellow"
    try {
        # Download rustup-init.exe
        $rustupInit = Join-Path $env:TEMP "rustup-init.exe"
        Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $rustupInit -ErrorAction Stop
        
        # Run rustup-init.exe with -y flag for automatic installation
        Start-Process -FilePath $rustupInit -ArgumentList "-y" -Wait -NoNewWindow
        
        # Check if installation was successful
        if (Test-RustInstalled) {
            Write-ColorOutput "  ✓ Rust has been successfully installed" "Green"
            return $true
        } else {
            Write-ColorOutput "Rust installation completed but rustc command not found." "Red"
            Write-ColorOutput "Please restart your PowerShell session and run the installer again." "Yellow"
            return $false
        }
    } catch {
        Write-ColorOutput "Failed to install Rust: $_" "Red"
        return $false
    } finally {
        # Clean up the installer
        if (Test-Path $rustupInit) {
            Remove-Item $rustupInit -Force
        }
    }
}

# Check if Rust is installed, if not, ask to install it
if (-not (Test-RustInstalled)) {
    Write-ColorOutput "Rust is not installed. Razen compiler requires Rust to run." "Yellow"
    Write-ColorOutput "Installing Rust automatically..." "Yellow"
    
    # Ask for confirmation
    $confirmation = Read-Host "Do you want to install Rust now? (y/n)"
    if ($confirmation -ne 'y') {
        Write-ColorOutput "Rust installation is required for Razen to function properly." "Red"
        Write-ColorOutput "You can install Rust manually by downloading the installer from:" "Yellow"
        Write-ColorOutput "  https://rustup.rs" "Cyan"
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    # Install Rust
    if (-not (Install-Rust)) {
        Write-ColorOutput "Failed to install Rust. Please install it manually." "Red"
        Write-ColorOutput "You can install Rust manually by downloading the installer from:" "Yellow"
        Write-ColorOutput "  https://rustup.rs" "Cyan"
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    # Refresh environment variables to include Rust binaries
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
} else {
    Write-ColorOutput "  ✓ Rust is already installed" "Green"
}

# Check Rust version
try {
    $rustVersion = (& rustc --version) -replace 'rustc\s+', ''
    Write-ColorOutput "  ✓ Rust version: $rustVersion" "Green"
} catch {
    Write-ColorOutput "  ✗ Could not determine Rust version" "Yellow"
}

# Create symbolic links
$result = Create-Symlinks -InstallDir $installDir
if ($result -ne 0) {
    Write-ColorOutput "Failed to create symbolic links." "Red"
    Remove-Item $TMP_DIR -Recurse -Force
    exit 1
}

# Clean up
Remove-Item $TMP_DIR -Recurse -Force
Write-ColorOutput "  ✓ Cleaned up temporary files" "Green"

# Ask about IDE extension installation
Write-ColorOutput "`nWould you like to install IDE extensions for Razen?" "Yellow"
Write-ColorOutput "1. VS Code Extension (works with VS Code and forks like VSCodium)" "Cyan"
Write-ColorOutput "2. JetBrains Plugin (works with IntelliJ IDEA, PyCharm, WebStorm, etc.)" "Cyan"
Write-ColorOutput "3. Skip (don't install IDE extensions)" "Cyan"

$ide_choice = Read-Host "Enter your choice (1-3)"
Write-Host ""

# Install IDE extensions based on user choice
switch ($ide_choice) {
    "1" {
        Write-ColorOutput "Installing VS Code Extension for Razen..." "Yellow"
        
        # Check if VS Code is installed
        if ((Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") -or 
            (Test-Path "$env:ProgramFiles\Microsoft VS Code\Code.exe") -or 
            (Test-Path "$env:LOCALAPPDATA\Programs\VSCodium\codium.exe")) {
            
            # Create VS Code extensions directory if it doesn't exist
            $VSCODE_EXT_DIR = "$env:USERPROFILE\.vscode\extensions\razen-lang.razen-language"
            New-Item -ItemType Directory -Path $VSCODE_EXT_DIR -Force | Out-Null
            
            # Copy VS Code extension files
            Copy-Item -Path "$installDir\razen-vscode-extension\*" -Destination $VSCODE_EXT_DIR -Recurse -Force
            
            Write-ColorOutput "  ✓ VS Code Extension installed successfully" "Green"
            Write-ColorOutput "  Location: $VSCODE_EXT_DIR" "Yellow"
            Write-ColorOutput "  Restart VS Code to activate the extension" "Yellow"
        } else {
            Write-ColorOutput "VS Code not detected. Installing extension files only..." "Yellow"
            
            # Create a directory in the user's home for the extension
            $VSCODE_EXT_DIR = "$env:USERPROFILE\.razen\vscode-extension"
            New-Item -ItemType Directory -Path $VSCODE_EXT_DIR -Force | Out-Null
            
            # Copy VS Code extension files
            Copy-Item -Path "$installDir\razen-vscode-extension\*" -Destination $VSCODE_EXT_DIR -Recurse -Force
            
            Write-ColorOutput "  ✓ VS Code Extension files installed to: $VSCODE_EXT_DIR" "Green"
            Write-ColorOutput "  To use with VS Code, copy these files to:" "Yellow"
            Write-ColorOutput "  %USERPROFILE%\.vscode\extensions\razen-lang.razen-language\" "Cyan"
        }
    }
    "2" {
        Write-ColorOutput "Installing JetBrains Plugin for Razen..." "Yellow"
        
        # Check if any JetBrains IDE is installed
        $JETBRAINS_FOUND = $false
        $ide_dirs = @("$env:USERPROFILE\.IntelliJIdea*", "$env:USERPROFILE\.PyCharm*", "$env:USERPROFILE\.WebStorm*")
        
        foreach ($dir_pattern in $ide_dirs) {
            if (Test-Path $dir_pattern) {
                $JETBRAINS_FOUND = $true
                break
            }
        }
        
        # Create a directory for the JetBrains plugin
        $JETBRAINS_PLUGIN_DIR = "$env:USERPROFILE\.razen\jetbrains-plugin"
        New-Item -ItemType Directory -Path $JETBRAINS_PLUGIN_DIR -Force | Out-Null
        
        # Copy JetBrains plugin files
        Copy-Item -Path "$installDir\razen-jetbrains-plugin\*" -Destination $JETBRAINS_PLUGIN_DIR -Recurse -Force
        
        if ($JETBRAINS_FOUND) {
            Write-ColorOutput "  ✓ JetBrains Plugin files installed to: $JETBRAINS_PLUGIN_DIR" "Green"
            Write-ColorOutput "  To activate the plugin:" "Yellow"
            Write-ColorOutput "  1. Open your JetBrains IDE" "White"
            Write-ColorOutput "  2. Go to Settings/Preferences > Plugins" "White"
            Write-ColorOutput "  3. Click the gear icon and select 'Install Plugin from Disk...'" "White"
            Write-ColorOutput "  4. Navigate to $JETBRAINS_PLUGIN_DIR and select the plugin JAR file" "White"
            Write-ColorOutput "     (You may need to build it first using Gradle)" "White"
        } else {
            Write-ColorOutput "  ✓ JetBrains Plugin files installed to: $JETBRAINS_PLUGIN_DIR" "Green"
            Write-ColorOutput "  No JetBrains IDE detected. To use the plugin:" "Yellow"
            Write-ColorOutput "  1. Build the plugin using Gradle: cd $JETBRAINS_PLUGIN_DIR && gradlew buildPlugin" "White"
            Write-ColorOutput "  2. Install the plugin from: $JETBRAINS_PLUGIN_DIR\build\distributions\" "White"
        }
    }
    default {
        Write-ColorOutput "Skipping IDE extension installation." "Yellow"
        Write-ColorOutput "You can install extensions later from:" "Cyan"
        Write-ColorOutput "  VS Code: $installDir\razen-vscode-extension\" "White"
        Write-ColorOutput "  JetBrains: $installDir\razen-jetbrains-plugin\" "White"
    }
}

# Success message
Write-ColorOutput "`n✅ Razen has been successfully installed!" "Green"
Write-ColorOutput "`nAvailable commands:" "Yellow"
Write-ColorOutput "  razen - Run Razen programs" "Green"
Write-ColorOutput "  razen-debug - Run Razen programs in debug mode" "Green"
Write-ColorOutput "  razen-test - Run Razen tests" "Green"
Write-ColorOutput "  razen-run - Run Razen programs with additional options" "Green"
Write-ColorOutput "  razen-update - Update Razen to the latest version" "Green"
Write-ColorOutput "  razen-help - Show help information" "Green"
Write-ColorOutput "  razen-extension - Manage IDE extensions for Razen" "Green"
Write-ColorOutput "  razen new myprogram - Create a new Razen program" "Green"
Write-ColorOutput "  razen version - Show Razen version" "Green"

Write-ColorOutput "`nExample usage:" "Yellow"
Write-ColorOutput "  razen run hello_world.rzn - Run a Razen program" "Green"
Write-ColorOutput "  razen new myprogram - Create a new program" "Green"
Write-ColorOutput "  razen-update - Update Razen" "Green"
Write-ColorOutput "  razen-help - Get help" "Green"

Write-ColorOutput "`nTo uninstall Razen:" "Yellow"
Write-ColorOutput "  razen uninstall" "Green"

Write-ColorOutput "`nNote: Razen is installed in C:\Program Files\Razen for security." "Yellow"
Write-ColorOutput "Official website and documentation will be available soon." "Yellow" 