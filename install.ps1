# Razen Language Installer for Windows
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.3

# Enable TLS 1.2 for all web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Repository URL
$RAZEN_REPO = "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"
$RAZEN_VERSION = "beta v0.1.3"

# Function to print colored text
function Write-ColorOutput {
    param(
        [string]$Text,
        [string]$Color
    )
    Write-Host $Text -ForegroundColor $Color
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
        $installerFile = Join-Path $env:TEMP "install.ps1"
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
        [string]$InstallDir,
        [string[]]$Scripts
    )
    
    Write-ColorOutput "Creating symbolic links..." "Yellow"
    $scriptsDir = Join-Path $InstallDir "scripts"
    
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
    
    return 0
}

# Function to uninstall Razen
function Uninstall-Razen {
    Write-ColorOutput "Uninstalling Razen..." "Yellow"
    
    $scripts = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help")
    $installDir = "C:\Program Files\Razen"
    
    # Remove symbolic links
    foreach ($script in $scripts) {
        $link = Join-Path $env:ProgramFiles "Razen\$script"
        if (Test-Path $link) {
            Remove-Item $link -Force
            Write-ColorOutput "  ✓ Removed symbolic link for $script" "Green"
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

# Check for uninstall flag
if ($args[0] -eq "--uninstall") {
    Uninstall-Razen
}

# Check for update flag or if already installed
$installDir = "C:\Program Files\Razen"
if ($args[0] -eq "update" -or $args[0] -eq "--update" -or (Test-Path (Join-Path $installDir "razen"))) {
    $updateStatus = Check-ForUpdates
    
    if ($updateStatus -eq 2) {
        $response = Read-Host "Do you want to update Razen? (y/n)"
        if ($response -notmatch '^[Yy]$') {
            Write-ColorOutput "Update cancelled." "Blue"
            Write-ColorOutput "Tip: You can use 'razen-update' to update Razen later." "Green"
            exit 0
        }
        
        # Perform the update
        $updateResult = Perform-Update
        if ($updateResult -ne 0) {
            Write-ColorOutput "Update failed. Please try again later." "Red"
            exit 1
        }
        exit 0
    } elseif ($updateStatus -eq 0) {
        Write-ColorOutput "Razen is already up to date." "Green"
        exit 0
    } else {
        Write-ColorOutput "Failed to check for updates." "Red"
        exit 1
    }
}

# Create installation directory
Write-ColorOutput "Creating installation directory..." "Yellow"
try {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    Write-ColorOutput "  ✓ Created installation directory" "Green"
} catch {
    Write-ColorOutput "  ✗ Failed to create installation directory" "Red"
    Write-ColorOutput "    Error: $_" "Red"
    exit 1
}

# Create temporary directory
$TMP_DIR = Join-Path $env:TEMP "razen-install"
try {
    New-Item -ItemType Directory -Force -Path $TMP_DIR | Out-Null
    Write-ColorOutput "  ✓ Created temporary directory" "Green"
} catch {
    Write-ColorOutput "  ✗ Failed to create temporary directory" "Red"
    Write-ColorOutput "    Error: $_" "Red"
    exit 1
}

# Download files
Write-ColorOutput "`nDownloading Razen files..." "Yellow"

# Download main files
$files = @(
    "main.py",
    "parser/parser.py",
    "parser/lexer.py",
    "parser/ast.py",
    "utils/utils.py",
    "utils/error.py"
)

foreach ($file in $files) {
    $url = "$RAZEN_REPO/$file"
    $outFile = Join-Path $TMP_DIR (Split-Path $file -Leaf)
    try {
        Invoke-WebRequest -Uri $url -OutFile $outFile -ErrorAction Stop
        Write-ColorOutput "  ✓ Downloaded $file" "Green"
    } catch {
        Write-ColorOutput "  ✗ Failed to download $file" "Red"
        Write-ColorOutput "    Error: $_" "Red"
        Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# Download scripts
$scripts = @(
    "razen",
    "razen-debug",
    "razen-test",
    "razen-run",
    "razen-update",
    "razen-help"
)

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $TMP_DIR "scripts") | Out-Null
} catch {
    Write-ColorOutput "  ✗ Failed to create scripts directory" "Red"
    Write-ColorOutput "    Error: $_" "Red"
    Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

foreach ($script in $scripts) {
    $url = "$RAZEN_REPO/scripts/$script"
    $outFile = Join-Path $TMP_DIR "scripts\$script"
    try {
        Invoke-WebRequest -Uri $url -OutFile $outFile -ErrorAction Stop
        Write-ColorOutput "  ✓ Downloaded $script" "Green"
    } catch {
        Write-ColorOutput "  ✗ Failed to download $script" "Red"
        Write-ColorOutput "    Error: $_" "Red"
        Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# Copy files to installation directory
Write-ColorOutput "`nInstalling files..." "Yellow"
try {
    Copy-Item -Path "$TMP_DIR\*" -Destination $installDir -Recurse -Force
    Write-ColorOutput "  ✓ Copied files to installation directory" "Green"
} catch {
    Write-ColorOutput "  ✗ Failed to copy files to installation directory" "Red"
    Write-ColorOutput "    Error: $_" "Red"
    Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Create version file
try {
    $RAZEN_VERSION | Out-File -FilePath "$installDir\version" -Encoding UTF8
    Write-ColorOutput "  ✓ Created version file" "Green"
} catch {
    Write-ColorOutput "  ✗ Failed to create version file" "Red"
    Write-ColorOutput "    Error: $_" "Red"
    Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Create symbolic links
$symlinkResult = Create-Symlinks -InstallDir $installDir -Scripts $scripts
if ($symlinkResult -ne 0) {
    Write-ColorOutput "Failed to create some symbolic links. Please check the errors above." "Red"
    Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Add to PATH
try {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$installDir*") {
        [Environment]::SetEnvironmentVariable("Path", $userPath + ";$installDir", "User")
        Write-ColorOutput "  ✓ Added Razen to PATH" "Green"
    }
} catch {
    Write-ColorOutput "  ✗ Failed to add Razen to PATH" "Red"
    Write-ColorOutput "    Error: $_" "Red"
    Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Clean up
Write-ColorOutput "`nCleaning up..." "Yellow"
try {
    Remove-Item -Path $TMP_DIR -Recurse -Force
    Write-ColorOutput "  ✓ Cleaned up temporary files" "Green"
} catch {
    Write-ColorOutput "  ✗ Failed to clean up temporary files" "Red"
    Write-ColorOutput "    Error: $_" "Red"
}

# Success message
Write-ColorOutput "`n✅ Razen has been successfully installed!" "Green"
Write-ColorOutput "`nAvailable commands:" "Yellow"
Write-ColorOutput "  razen - Run Razen programs" "Green"
Write-ColorOutput "  razen-debug - Run programs in debug mode" "Green"
Write-ColorOutput "  razen-test - Run programs in test mode" "Green"
Write-ColorOutput "  razen-run - Run programs with clean output" "Green"
Write-ColorOutput "  razen-update - Update Razen to the latest version" "Green"
Write-ColorOutput "  razen-help - Show help information" "Green"
Write-ColorOutput "  razen new myprogram - Create a new program" "Green"
Write-ColorOutput "  razen version - Show version information" "Green"
Write-ColorOutput "  razen uninstall - Remove Razen from your system" "Green"

Write-ColorOutput "`nExample usage:" "Yellow"
Write-ColorOutput "  razen run hello_world.rzn - Run a Razen program" "Green"
Write-ColorOutput "  razen new myprogram - Create a new program" "Green"
Write-ColorOutput "  razen-update - Update Razen" "Green"
Write-ColorOutput "  razen-help - Get help" "Green"

Write-ColorOutput "`nNote: You may need to restart your terminal for the PATH changes to take effect." "Yellow" 