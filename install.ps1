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
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red" # More specific error
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
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red" # More specific error
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
            $Scripts = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help") # Assuming fallback needed
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

# --- Main Script Logic ---

# Print banner
# FIX: Enclose here-string in parentheses when passing as an argument alongside other arguments
Write-ColorOutput (@"
██████╗  █████╗ ███████╗███████╗███╗   ██╗
██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║
██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║
██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║███████╗███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
"@) "Blue" # Corrected syntax

Write-ColorOutput "Programming Language $RAZEN_VERSION" "Yellow"
Write-ColorOutput "By Prathmesh Barot, Basai Corporation" "Cyan"
Write-ColorOutput "Copyright © 2025 Prathmesh Barot`n" "Yellow"

# Small delay to make the banner more readable
Start-Sleep -Seconds 1

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ColorOutput "This script requires administrator privileges." "Red"
    Write-ColorOutput "Please right-click the PowerShell window or shortcut and select 'Run as administrator'." "Yellow"
    exit 1
}

# Create temporary directory
$TMP_DIR = Join-Path $env:TEMP "razen-install-$($PID)-$(Get-Random)" # Make temp dir more unique
try {
    if (Test-Path $TMP_DIR) { Remove-Item $TMP_DIR -Recurse -Force } # Clean up previous attempt if exists
    New-Item -ItemType Directory -Path $TMP_DIR -Force -ErrorAction Stop | Out-Null
    Write-ColorOutput "  ✓ Created temporary directory: $TMP_DIR" "Green"
} catch {
    Write-ColorOutput "Failed to create temporary directory: $TMP_DIR" "Red"
    Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
    exit 1
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
        Write-ColorOutput "Failed to create directory: $dir" "Red"
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        # No cleanup here, rely on trap
        exit 1
    }
}
Write-ColorOutput "  ✓ Installation directory structure prepared." "Green"


# Helper function for downloads
function Download-File {
    param(
        [string]$Uri,
        [string]$OutFilePath,
        [string]$Description
    )
    Write-ColorOutput "  Downloading $Description..." "Cyan"
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFilePath -UseBasicParsing -ErrorAction Stop
        Write-ColorOutput "    ✓ Downloaded $Description" "Green"
        return $true
    } catch {
        Write-ColorOutput "    ✗ Failed to download $Description from $Uri" "Red"
        Write-ColorOutput "      Error: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Download Razen core files to temporary directory
Write-ColorOutput "Downloading Razen core files..." "Yellow"
$downloadSuccess = $true

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


# Check if all essential downloads were successful
if (-not $downloadSuccess) {
    Write-ColorOutput "One or more essential files failed to download. Installation cannot continue." "Red"
    # Cleanup handled by trap
    exit 1
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
     Write-ColorOutput "Failed to copy downloaded files to installation directory." "Red"
     Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
     # Cleanup handled by trap
     exit 1
}

# Download and save the latest installer script (this script) for future updates
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
     Write-ColorOutput "Failed to create version file in $installDir." "Red"
     Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
     # Cleanup handled by trap
     exit 1
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

# Function to check if Rust is installed
function Test-RustInstalled {
    $rustcPath = Get-Command rustc -ErrorAction SilentlyContinue
    return ($rustcPath -ne $null)
}

# Function to install Rust using rustup
function Install-Rust {
    Write-ColorOutput "Attempting to install Rust via rustup..." "Yellow"
    $rustupInit = "" # Scope fix
    try {
        # Download rustup-init.exe to temp dir
        $rustupInit = Join-Path $env:TEMP "rustup-init-$($PID).exe"
        Write-ColorOutput "  Downloading rustup installer..." "Cyan"
        Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $rustupInit -UseBasicParsing -ErrorAction Stop

        # Run rustup-init.exe with -y flag for non-interactive default installation
        Write-ColorOutput "  Running rustup installer (non-interactive)..." "Cyan"
        Write-ColorOutput "  This may take a few minutes. Please wait." "Cyan"
        # Use Start-Process with -Wait to ensure it finishes
        $process = Start-Process -FilePath $rustupInit -ArgumentList "-y --no-modify-path" -Wait -PassThru -NoNewWindow #-ErrorAction Stop # Add --no-modify-path? Let rustup handle it?

        if ($process.ExitCode -ne 0) {
            Write-ColorOutput "Rustup installer exited with code $($process.ExitCode)." "Red"
            Write-ColorOutput "Please check for errors above or try installing manually from https://rustup.rs" "Yellow"
            return $false
        }

        # Add Rust's cargo bin directory to the current session's PATH
        # This is crucial for the *current* script execution if rustc wasn't found before.
        $cargoBinPath = Join-Path $env:USERPROFILE ".cargo\bin"
        if (Test-Path $cargoBinPath) {
            Write-ColorOutput "  Adding '$cargoBinPath' to PATH for current session..." "Cyan"
            $env:Path = "$($env:Path);$cargoBinPath"
        } else {
            Write-ColorOutput "  Could not find '$cargoBinPath' after installation." "Yellow"
        }

        # Re-check if rustc is now available
        if (Test-RustInstalled) {
            Write-ColorOutput "  ✓ Rust seems to be installed successfully." "Green"
            Write-ColorOutput "    Note: A system restart or new PowerShell session might be needed for Rust to be available everywhere." "Yellow"
            return $true
        } else {
            Write-ColorOutput "Rust installation finished, but 'rustc' command is still not found in this session." "Red"
            Write-ColorOutput "Please restart PowerShell/CMD or your system, then try installing Razen again." "Yellow"
            Write-ColorOutput "If the problem persists, install Rust manually from https://rustup.rs" "Yellow"
            return $false
        }
    } catch {
        Write-ColorOutput "Failed during Rust installation process." "Red"
        Write-ColorOutput "Error: $($_.Exception.Message)" "Red"
        Write-ColorOutput "Please install Rust manually from https://rustup.rs" "Yellow"
        return $false
    } finally {
        # Clean up the rustup installer
        if (($rustupInit) -and (Test-Path $rustupInit)) {
            Remove-Item $rustupInit -Force -ErrorAction SilentlyContinue
        }
    }
}

# Check if Rust is installed, if not, prompt to install it
if (-not (Test-RustInstalled)) {
    Write-ColorOutput "Rust (rustc command) not found in PATH. Razen compiler requires Rust." "Yellow"
    Write-ColorOutput "Do you want to attempt automatic installation using rustup (recommended)? (y/n)" "Yellow"
    $confirmation = Read-Host

    if ($confirmation -match '^[Yy]$') {
        if (-not (Install-Rust)) {
            Write-ColorOutput "Automatic Rust installation failed or was incomplete." "Red"
            Write-ColorOutput "Razen installation cannot proceed without Rust." "Red"
            Write-ColorOutput "Please install Rust manually from https://rustup.rs and run this installer again." "Yellow"
            # Cleanup handled by trap
            exit 1
        }
        # If Install-Rust succeeded, Rust *should* be available now in the session PATH
    } else {
        Write-ColorOutput "Rust installation skipped." "Blue"
        Write-ColorOutput "Razen installation cannot proceed without Rust." "Red"
        Write-ColorOutput "Please install Rust manually from https://rustup.rs and run this installer again." "Yellow"
        # Cleanup handled by trap
        exit 1
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
    Write-ColorOutput "Failed to create symbolic links or update PATH correctly." "Red"
    Write-ColorOutput "Razen might not be accessible from the command line." "Yellow"
    Write-ColorOutput "Check previous error messages for details." "Yellow"
    # Decide whether to exit or continue
    # exit 1 # Exit if symlinks are critical
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
switch ($ide_choice) {
    "1" {
        Write-ColorOutput "Installing VS Code Extension files..." "Yellow"
        $vscodeExtSourceDir = Join-Path $installDir "razen-vscode-extension"
        $vscodeUserExtDir = Join-Path $env:USERPROFILE ".vscode\extensions"
        $razenVscodeExtTargetDir = Join-Path $vscodeUserExtDir "basai-corp.razen-language" # Use publisher.name format

        if (-not (Test-Path $vscodeExtSourceDir)) {
             Write-ColorOutput "  ✗ Source directory not found: $vscodeExtSourceDir" "Red"
             Write-ColorOutput "    Skipping VS Code extension installation." "Yellow"
             break # Exit this case
        }

        # Check if VS Code extensions directory exists
        if (Test-Path $vscodeUserExtDir) {
             Write-ColorOutput "  Found VS Code extensions directory: $vscodeUserExtDir" "Cyan"
             try {
                 # Create the specific extension directory
                 if (-not(Test-Path $razenVscodeExtTargetDir)) {
                     New-Item -ItemType Directory -Path $razenVscodeExtTargetDir -Force -ErrorAction Stop | Out-Null
                 }
                 # Copy files from install dir to VS Code extensions dir
                 Copy-Item -Path (Join-Path $vscodeExtSourceDir "*") -Destination $razenVscodeExtTargetDir -Recurse -Force -ErrorAction Stop
                 Write-ColorOutput "  ✓ VS Code Extension files copied successfully to:" "Green"
                 Write-ColorOutput "    $razenVscodeExtTargetDir" "Green"
                 Write-ColorOutput "    Restart VS Code to activate the extension." "Yellow"
             } catch {
                  Write-ColorOutput "  ✗ Failed to copy VS Code extension files." "Red"
                  Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
                  Write-ColorOutput "    You can manually copy files from '$vscodeExtSourceDir'." "Yellow"
             }
        } else {
            Write-ColorOutput "  VS Code user extensions directory not found at '$vscodeUserExtDir'." "Yellow"
            Write-ColorOutput "  Razen VS Code extension files are available in:" "Cyan"
            Write-ColorOutput "  $vscodeExtSourceDir" "Cyan"
            Write-ColorOutput "  You can install manually if you have VS Code." "Yellow"
        }
    }
    "2" {
        Write-ColorOutput "Installing JetBrains Plugin files..." "Yellow"
        $jetbrainsPluginSourceDir = Join-Path $installDir "razen-jetbrains-plugin"
        $jetbrainsUserPluginDir = Join-Path $env:APPDATA "JetBrains" # Common base for plugins, might vary
        $razenJetbrainsPluginTargetDir = Join-Path $env:USERPROFILE ".razen\jetbrains-plugin" # Fallback location

        if (-not (Test-Path $jetbrainsPluginSourceDir)) {
             Write-ColorOutput "  ✗ Source directory not found: $jetbrainsPluginSourceDir" "Red"
             Write-ColorOutput "    Skipping JetBrains plugin installation." "Yellow"
             break # Exit this case
        }

        # Just copy files to a known location and provide instructions, as auto-install is complex.
        try {
             New-Item -ItemType Directory -Path $razenJetbrainsPluginTargetDir -Force -ErrorAction Stop | Out-Null
             Copy-Item -Path (Join-Path $jetbrainsPluginSourceDir "*") -Destination $razenJetbrainsPluginTargetDir -Recurse -Force -ErrorAction Stop
             Write-ColorOutput "  ✓ JetBrains Plugin files copied to:" "Green"
             Write-ColorOutput "    $razenJetbrainsPluginTargetDir" "Green"
             Write-ColorOutput "  To install in your JetBrains IDE (IntelliJ, PyCharm, etc.):" "Yellow"
             Write-ColorOutput "  1. Build the plugin if necessary (e.g., using Gradle/Maven inside the plugin dir)." "White"
             Write-ColorOutput "  2. Open IDE > Settings/Preferences > Plugins." "White"
             Write-ColorOutput "  3. Click the Gear icon > 'Install Plugin from Disk...'." "White"
             Write-ColorOutput "  4. Select the built plugin JAR/ZIP file from '$razenJetbrainsPluginTargetDir' (or its build output)." "White"
        } catch {
            Write-ColorOutput "  ✗ Failed to copy JetBrains plugin files." "Red"
            Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
            Write-ColorOutput "    Plugin source is available at '$jetbrainsPluginSourceDir'." "Yellow"
        }
    }
    default {
        Write-ColorOutput "Skipping IDE extension installation." "Yellow"
        Write-ColorOutput "Extension files are available in '$installDir'." "Cyan"
    }
} # End switch

# --- Final Success Message ---
Write-ColorOutput "`n✅ Razen Language $RAZEN_VERSION has been successfully installed!" "Green"
Write-ColorOutput "`nInstallation Directory: $installDir" "Cyan"

Write-ColorOutput "`nAvailable commands (try in a new terminal):" "Yellow"
# List commands based on the $Scripts variable populated during symlink creation
$availableScripts = Get-ChildItem (Join-Path $installDir "scripts") -File | Select-Object -ExpandProperty Name
if ($availableScripts) {
    foreach($cmd in $availableScripts) {
         Write-ColorOutput "  $cmd" "Green"
    }
} else {
     Write-ColorOutput "  (Could not list commands, check $installDir\scripts)" "Yellow"
}
Write-ColorOutput "  (And potentially others like 'razen new', 'razen version')" "Green"

Write-ColorOutput "`nExample usage:" "Yellow"
Write-ColorOutput "  razen run your_program.rzn" "Green"
Write-ColorOutput "  razen new my_project" "Green"
Write-ColorOutput "  razen-update" "Green"
Write-ColorOutput "  razen --uninstall (Run this script with --uninstall argument)" "Green"

Write-ColorOutput "`nImportant: You may need to RESTART your PowerShell/CMD terminal for the PATH changes and new commands to take effect." "Yellow"

Write-ColorOutput "`nOfficial website and documentation will be available soon." "Yellow"

# Remove the trap handler cleanly before exiting
trap -Remove [Exception]
exit 0