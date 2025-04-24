# Razen Language Installer for Windows
# Copyright 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.6589 (Libraries Update new libs added image and date and etc.)

# Enable TLS 1.2 for all web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Repository URLs
$RAZEN_REPO = "https://raw.githubusercontent.com/BasaiCorp/Razen-Lang/main"
$RAZEN_GIT_REPO = "https://github.com/BasaiCorp/Razen-Lang.git"

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

# Function to check if Git is installed
function Test-GitInstalled {
    try {
        $gitVersion = (git --version 2>$null)
        if ($gitVersion) {
            Write-ColorOutput "  ✓ Git detected: $gitVersion" "Green"
            return $true
        }
        Write-ColorOutput "  ✗ Git not found" "Red"
        return $false
    } catch {
        Write-ColorOutput "  ✗ Git not found" "Red"
        return $false
    }
}

# Function to clone the GitHub repository
function Clone-GitRepository {
    param (
        [string]$TargetDir
    )
    
    Write-ColorOutput "Cloning the Razen GitHub repository..." "Yellow"
    
    # Check if git is installed
    if (-not (Test-GitInstalled)) {
        Write-ColorOutput "Git is not installed. Please install Git first." "Red"
        Write-ColorOutput "You can download Git from https://git-scm.com/downloads" "Yellow"
        return $false
    }
    
    # Try to clone from the official repository
    Write-ColorOutput "  Attempting to clone from: $RAZEN_GIT_REPO" "Cyan"
    try {
        git clone --depth 1 $RAZEN_GIT_REPO "$TargetDir\razen-repo" 2>$null
        if (Test-Path "$TargetDir\razen-repo") {
            Write-ColorOutput "  ✓ Successfully cloned Razen repository" "Green"
            
            # Count and log files in the cloned repository
            $fileCount = (Get-ChildItem -Recurse -File "$TargetDir\razen-repo").Count
            Write-ColorOutput "  ✓ Cloned repository contains $fileCount files" "Green"
            
            # List key directories to verify
            foreach ($dir in @("src", "properties", "scripts")) {
                if (Test-Path "$TargetDir\razen-repo\$dir") {
                    $dirFileCount = (Get-ChildItem -Recurse -File "$TargetDir\razen-repo\$dir").Count
                    Write-ColorOutput "  ✓ Found $dir directory with $dirFileCount files" "Green"
                } else {
                    Write-ColorOutput "  ⚠ Directory $dir not found in cloned repository" "Yellow"
                }
            }
            
            return $true
        }
    } catch {
        # Try a fallback repository if the main one fails
        Write-ColorOutput "Main repository clone failed, trying fallback..." "Yellow"
        
        try {
            git clone --depth 1 "https://github.com/BasaiCorp/Razen-Lang.git" "$TargetDir\razen-repo" 2>$null
            if (Test-Path "$TargetDir\razen-repo") {
                Write-ColorOutput "  ✓ Successfully cloned from fallback repository" "Green"
                
                # Count and log files in the cloned repository
                $fileCount = (Get-ChildItem -Recurse -File "$TargetDir\razen-repo").Count
                Write-ColorOutput "  ✓ Cloned repository contains $fileCount files" "Green"
                
                # List key directories to verify
                foreach ($dir in @("src", "properties", "scripts")) {
                    if (Test-Path "$TargetDir\razen-repo\$dir") {
                        $dirFileCount = (Get-ChildItem -Recurse -File "$TargetDir\razen-repo\$dir").Count
                        Write-ColorOutput "  ✓ Found $dir directory with $dirFileCount files" "Green"
                    } else {
                        Write-ColorOutput "  ⚠ Directory $dir not found in cloned repository" "Yellow"
                    }
                }
                
                return $true
            }
        } catch {
            Write-ColorOutput "All git clone attempts failed" "Red"
            return $false
        }
    }
    
    Write-ColorOutput "Failed to clone repository" "Red"
    return $false
}

# Function to copy files from the cloned repository
function Copy-FromRepository {
    param (
        [string]$SourceDir,
        [string]$TargetDir
    )
    
    Write-ColorOutput "Copying files from cloned repository..." "Yellow"
    
    # Check if the repository was cloned successfully
    $repoDir = Join-Path $SourceDir "razen-repo"
    if (-not (Test-Path $repoDir)) {
        Write-ColorOutput "  ✗ Repository directory not found." "Red"
        return $false
    }
    
    # Define required folders to copy
    $requiredFolders = @("src", "properties", "scripts", "examples", "docs", "razen-vscode-extension", "razen-jetbrains-plugin")
    
    # Initialize counters for detailed logging
    $totalCopied = 0
    $totalMissing = 0
    $copiedFilesList = @()
    
    # Copy files from the cloned repository
    try {
        # Copy main.py if it exists
        if (Test-Path "$repoDir\main.py") {
            Copy-Item "$repoDir\main.py" "$TargetDir\main.py" -Force
            Write-ColorOutput "  ✓ Copied main.py" "Green"
            $totalCopied++
            $copiedFilesList += "main.py"
        } else {
            Write-ColorOutput "  ⚠ main.py not found in repository" "Yellow"
            $totalMissing++
        }
        
        # Copy Cargo.toml if it exists
        if (Test-Path "$repoDir\Cargo.toml") {
            Copy-Item "$repoDir\Cargo.toml" "$TargetDir\Cargo.toml" -Force
            Write-ColorOutput "  ✓ Copied Cargo.toml" "Green"
            $totalCopied++
            $copiedFilesList += "Cargo.toml"
        } else {
            Write-ColorOutput "  ⚠ Cargo.toml not found in repository" "Yellow"
            $totalMissing++
        }
        
        # Copy each required folder
        foreach ($folder in $requiredFolders) {
            if (Test-Path "$repoDir\$folder") {
                Write-ColorOutput "  Copying $folder/ directory..." "Blue"
                
                # Create the target directory if it doesn't exist
                if (-not (Test-Path "$TargetDir\$folder")) {
                    New-Item -ItemType Directory -Path "$TargetDir\$folder" -Force | Out-Null
                }
                
                # Get file count before copying
                $filesBefore = (Get-ChildItem "$TargetDir\$folder" -Recurse -File).Count
                
                # Copy all files and subdirectories recursively
                Copy-Item "$repoDir\$folder\*" "$TargetDir\$folder" -Recurse -Force -ErrorAction SilentlyContinue
                
                # Get file count after copying
                $filesAfter = (Get-ChildItem "$TargetDir\$folder" -Recurse -File).Count
                $filesCopied = $filesAfter - $filesBefore
                
                if ($filesCopied -gt 0) {
                    Write-ColorOutput "  ✓ Copied $filesCopied files from $folder directory" "Green"
                    $totalCopied += $filesCopied
                    
                    # Log some sample files (up to 5)
                    $sampleFiles = Get-ChildItem "$TargetDir\$folder" -Recurse -File | Select-Object -First 5 | ForEach-Object { $_.Name }
                    Write-ColorOutput "    Sample files: $($sampleFiles -join ', ')" "Blue"
                    
                    $copiedFilesList += "$folder"
                } else {
                    Write-ColorOutput "  ⚠ No files copied from $folder (directory empty or copy failed)" "Yellow"
                    $totalMissing++
                }
            } else {
                Write-ColorOutput "  ⚠ $folder not found in repository, creating empty directory" "Yellow"
                New-Item -ItemType Directory -Path "$TargetDir\$folder" -Force | Out-Null
                $totalMissing++
            }
        }
        
        # Check for src/functions and properties/libs subdirectories
        Write-ColorOutput "Checking for important subdirectories:" "Cyan"
        
        # Check for src/functions
        if (Test-Path "$TargetDir\src\functions") {
            $funcCount = (Get-ChildItem "$TargetDir\src\functions" -File).Count
            Write-ColorOutput "  ✓ Found src/functions directory with $funcCount files" "Green"
        } else {
            Write-ColorOutput "  ⚠ src/functions directory not found, creating it" "Yellow"
            New-Item -ItemType Directory -Path "$TargetDir\src\functions" -Force | Out-Null
        }
        
        # Check for properties/libs
        if (Test-Path "$TargetDir\properties\libs") {
            $libsCount = (Get-ChildItem "$TargetDir\properties\libs" -File).Count
            Write-ColorOutput "  ✓ Found properties/libs directory with $libsCount files" "Green"
        } else {
            Write-ColorOutput "  ⚠ properties/libs directory not found, creating it" "Yellow"
            New-Item -ItemType Directory -Path "$TargetDir\properties\libs" -Force | Out-Null
        }
        
        # Summary of copied files
        Write-ColorOutput "Copy summary:" "Cyan"
        Write-ColorOutput "  ✓ Successfully copied $totalCopied files from repository" "Green"
        if ($totalMissing -gt 0) {
            Write-ColorOutput "  ⚠ $totalMissing directories or files were missing or empty" "Yellow"
        }
        
        # Return success if we copied at least some files
        if ($totalCopied -gt 0) {
            return $true
        } else {
            Write-ColorOutput "  ✗ No files were copied from the repository." "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "  ✗ Error copying files from repository: $($_.Exception.Message)" "Red"
        return $false
    }
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

        # Build arguments for the installer
        $updateArgs = @()
        if ($FORCE_UPDATE) {
            $updateArgs += "--force-update"
        } else {
            $updateArgs += "--update"
        }
        
        # Add installation path
        if ($installDir) {
            $updateArgs += "--path=$installDir"
        }

        # Run the installer with the latest version and arguments
        Write-ColorOutput "Running installer with arguments: $updateArgs" "Yellow"
        & $installerFile $updateArgs
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

# Function to create a default Cargo.toml file
function Create-DefaultCargoToml {
    param (
        [string]$TargetFile
    )
    
    Write-ColorOutput "Creating default Cargo.toml file..." "Yellow"
    
    $cargoContent = @"
[package]
name = "razen_compiler"
version = "0.1.0"
edition = "2021"

[dependencies]
# For machine code generation
cranelift = "0.100.0"
cranelift-module = "0.100.0"
cranelift-jit = "0.100.0"
cranelift-object = "0.100.0"
target-lexicon = "0.12.12"
cc = "1.0.83"

# Error handling helper
thiserror = "1.0"

# For library system
rand = "0.8"
rand_chacha = "0.3"
lazy_static = "1.4"
chrono = "0.4"
serde_json = "1.0"

# For crypto library
sha2 = "0.10"
base64 = "0.21"
aes-gcm = "0.10"
hkdf = "0.12"

# For regex library
regex = "1.9"

# For UUID library
uuid = { version = "1.4", features = ["v4", "serde"] }

# For networking and HTTP requests
curl = "0.4.44"
reqwest = { version = "0.11", features = ["blocking", "json"] }
tokio = { version = "1", features = ["full"] }

# For logging
log = "0.4"
env_logger = "0.10"
"@
    
    try {
        Set-Content -Path $TargetFile -Value $cargoContent -Force -ErrorAction Stop
        Write-ColorOutput "  ✓ Created default Cargo.toml file" "Green"
        return $true
    } catch {
        Write-ColorOutput "  ✗ Failed to create Cargo.toml file" "Red"
        Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to verify directory structure after copying
function Verify-DirectoryStructure {
    param (
        [string]$TargetDir
    )
    
    Write-ColorOutput "Verifying directory structure..." "Yellow"
    
    foreach ($dir in @("src", "properties", "scripts")) {
        if (Test-Path "$TargetDir\$dir") {
            $dirFileCount = (Get-ChildItem -Recurse -File "$TargetDir\$dir").Count
            Write-ColorOutput "  ✓ $dir directory contains $dirFileCount files" "Green"
        } else {
            Write-ColorOutput "  ✗ $dir directory is missing" "Red"
            return $false
        }
    }
    
    # Check for specific important subdirectories
    if (-not (Test-Path "$TargetDir\src\functions")) {
        Write-ColorOutput "  ⚠ src/functions directory is missing, creating it" "Yellow"
        New-Item -ItemType Directory -Path "$TargetDir\src\functions" -Force | Out-Null
    }
    
    if (-not (Test-Path "$TargetDir\properties\libs")) {
        Write-ColorOutput "  ⚠ properties/libs directory is missing, creating it" "Yellow"
        New-Item -ItemType Directory -Path "$TargetDir\properties\libs" -Force | Out-Null
    }
    
    # Check for Cargo.toml
    if (-not (Test-Path "$TargetDir\Cargo.toml")) {
        Write-ColorOutput "  ⚠ Cargo.toml is missing, creating a default one" "Yellow"
        Create-DefaultCargoToml -TargetFile "$TargetDir\Cargo.toml"
    }
    
    return $true
}

# Function to check for Rust installation
function Test-RustInstalled {
    try {
        $rustcVersion = (rustc --version 2>$null)
        if ($rustcVersion) {
            $rustcVersionNum = $rustcVersion -replace 'rustc ([0-9]+\.[0-9]+\.[0-9]+).*', '$1'
            Write-ColorOutput "  ✓ Rustc detected: $rustcVersion" "Green"
            
            # Check if rustc version is sufficient (needs 1.60.0 or higher)
            if ([version]$rustcVersionNum -ge [version]"1.60.0") {
                Write-ColorOutput "  ✓ Rustc version is sufficient (>= 1.60.0)" "Green"
            } else {
                Write-ColorOutput "  ⚠ Rustc version is too old (< 1.60.0), consider updating" "Yellow"
            }
            
            # Check for cargo
            $cargoVersion = (cargo --version 2>$null)
            if ($cargoVersion) {
                Write-ColorOutput "  ✓ Cargo detected: $cargoVersion" "Green"
                
                # Check if cargo can find required dependencies
                Write-ColorOutput "  Checking cargo environment..." "Cyan"
                try {
                    $cargoList = (cargo --list 2>$null)
                    Write-ColorOutput "  ✓ Cargo environment is working properly" "Green"
                } catch {
                    Write-ColorOutput "  ⚠ Cargo environment may have issues" "Yellow"
                }
                
                # Check for rustup (for better Rust management)
                try {
                    $rustupVersion = (rustup --version 2>$null)
                    if ($rustupVersion) {
                        Write-ColorOutput "  ✓ Rustup detected: $rustupVersion" "Green"
                        
                        # Check active toolchain
                        $activeToolchain = (rustup show active-toolchain 2>$null)
                        Write-ColorOutput "  ✓ Active Rust toolchain: $activeToolchain" "Green"
                    }
                } catch {
                    Write-ColorOutput "  ⚠ Rustup not found (recommended for managing Rust)" "Yellow"
                }
                
                Write-ColorOutput "  ✓ Rust is properly installed" "Green"
                return $true
            } else {
                Write-ColorOutput "  ✗ Cargo not found" "Red"
                return $false
            }
        } else {
            Write-ColorOutput "  ✗ Rustc not found" "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "  ✗ Rust is not installed or not properly configured" "Red"
        return $false
    }
}

# Function to install Rust
function Install-Rust {
    Write-ColorOutput "Installing Rust..." "Yellow"
    
    try {
        # Download rustup-init.exe
        $rustupInitUrl = "https://win.rustup.rs/x86_64"
        $rustupInitPath = "$env:TEMP\rustup-init.exe"
        
        Write-ColorOutput "  Downloading Rust installer..." "Cyan"
        Invoke-WebRequest -Uri $rustupInitUrl -OutFile $rustupInitPath -UseBasicParsing
        
        if (Test-Path $rustupInitPath) {
            Write-ColorOutput "  ✓ Downloaded Rust installer" "Green"
            
            # Run rustup-init.exe with default settings
            Write-ColorOutput "  Installing Rust (this may take a few minutes)..." "Cyan"
            Start-Process -FilePath $rustupInitPath -ArgumentList "-y" -Wait
            
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            
            # Verify installation
            if (Test-RustInstalled) {
                Write-ColorOutput "  ✓ Rust has been successfully installed" "Green"
                return $true
            } else {
                Write-ColorOutput "  ✗ Rust installation verification failed" "Red"
                Write-ColorOutput "    You may need to restart your PowerShell session" "Yellow"
                return $false
            }
        } else {
            Write-ColorOutput "  ✗ Failed to download Rust installer" "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "  ✗ Failed to install Rust" "Red"
        Write-ColorOutput "    Error: $($_.Exception.Message)" "Red"
        Write-ColorOutput "    Please install Rust manually from https://rustup.rs" "Yellow"
        return $false
    } finally {
        # Clean up the installer
        if (Test-Path $rustupInitPath) {
            Remove-Item $rustupInitPath -Force -ErrorAction SilentlyContinue
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
                            "open" = "```
                            "close" = "```
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
                            "begin" = "```
                            "end" = "```
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
    Write-ColorOutput "  • GitHub: https://github.com/BasaiCorp/Razen-Lang" "White"
    Write-ColorOutput "  • Documentation: Coming soon" "White"
    Write-ColorOutput "  • Report Issues: https://github.com/BasaiCorp/Razen-Lang/issues" "White"
    
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

# Define default installation directory
$installDir = "C:\Program Files\Razen"

# Check if we're running with admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If not running as admin, use local app data instead
if (-not $isAdmin) {
    $installDir = "$env:LOCALAPPDATA\Razen"
    Write-ColorOutput "Running without admin privileges. Will install to $installDir" "Yellow"
}

# Check for update action or if already installed (presence of version file)
$versionFilePath = Join-Path $installDir "version"

# Check if Razen is installed in other locations
if (-not (Test-Path $versionFilePath)) {
    $alternateInstallDirs = @(
        "$env:LOCALAPPDATA\Razen",
        "$env:USERPROFILE\Razen",
        "$env:ProgramFiles\Razen",
        "$env:ProgramFiles(x86)\Razen"
    )
    
    foreach ($altDir in $alternateInstallDirs) {
        $altVersionPath = Join-Path $altDir "version"
        if (Test-Path $altVersionPath) {
            $installDir = $altDir
            $versionFilePath = $altVersionPath
            Write-ColorOutput "Found existing Razen installation at $installDir" "Cyan"
            break
        }
    }
}

if ($DO_UPDATE_CHECK -or (Test-Path $versionFilePath)) {
    if ($DO_UPDATE_CHECK) { Write-ColorOutput "Update requested." "Cyan"}
    elseif (Test-Path $versionFilePath) { Write-ColorOutput "Existing installation detected at $installDir. Checking for updates." "Cyan"}

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
        
        # Show success message after update
        Write-ColorOutput "\n✅ Razen has been successfully updated to version $LATEST_VERSION!" "Green"
        Write-ColorOutput "\nAvailable commands:" "Yellow"
        Write-ColorOutput "  razen - Run Razen programs" "Green"
        Write-ColorOutput "  razen-debug - Run Razen programs in debug mode" "Green"
        Write-ColorOutput "  razen-test - Run Razen tests" "Green"
        Write-ColorOutput "  razen-run - Run Razen programs with additional options" "Green"
        Write-ColorOutput "  razen-update - Update Razen to the latest version" "Green"
        Write-ColorOutput "  razen-help - Show help information" "Green"
        Write-ColorOutput "  razen new myprogram - Create a new Razen program" "Green"
        Write-ColorOutput "  razen version - Show Razen version" "Green"
        
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
    (Join-Path $installDir "src\functions"),
    (Join-Path $installDir "properties"),
    (Join-Path $installDir "properties\libs"),
    (Join-Path $installDir "scripts"),
    (Join-Path $installDir "examples"),
    (Join-Path $installDir "examples\web-example"),
    (Join-Path $installDir "razen-vscode-extension"),
    (Join-Path $installDir "razen-vscode-extension\src"),
    (Join-Path $installDir "razen-vscode-extension\syntaxes"),
    (Join-Path $installDir "razen-vscode-extension\language-configuration"),
    (Join-Path $installDir "razen-vscode-extension\snippets"),
    (Join-Path $installDir "razen-vscode-extension\icons"),
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

# Flag to determine if we should use direct download
$USE_DIRECT_DOWNLOAD = $false

# First attempt to clone the GitHub repository
Write-ColorOutput "Attempting to clone the GitHub repository..." "Yellow"
if (Clone-GitRepository -TargetDir $TMP_DIR) {
    Write-ColorOutput "✓ Successfully cloned the GitHub repository" "Green"
    
    # Copy files from the cloned repository
    if (Copy-FromRepository -SourceDir $TMP_DIR -TargetDir $TMP_DIR) {
        Write-ColorOutput "✓ Successfully copied files from the cloned repository" "Green"
        $USE_DIRECT_DOWNLOAD = $false
        
        # Verify the directory structure
        Write-ColorOutput "Verifying directory structure:" "Cyan"
        Verify-DirectoryStructure -TargetDir $TMP_DIR
    } else {
        Write-ColorOutput "Failed to copy files from cloned repository. Trying direct download method..." "Yellow"
        $USE_DIRECT_DOWNLOAD = $true
    }
} else {
    # Fallback to the direct download method if cloning fails
    Write-ColorOutput "Git clone failed. Trying direct download method..." "Yellow"
    $USE_DIRECT_DOWNLOAD = $true
}

# If direct download is needed
if ($USE_DIRECT_DOWNLOAD) {
    # Helper function for downloads
    $maxRetries = 3
    $retryCount = 0
    $downloadSuccess = $false

    while (-not $downloadSuccess -and $retryCount -lt $maxRetries) {
        try {
            # Download main.py
            if (-not (Download-File -Uri "$RAZEN_REPO/main.py" -OutFilePath (Join-Path $TMP_DIR "main.py") -Description "main.py")) { $downloadSuccess = $false }
            
            # Download src files
            $srcFiles = @("main.rs", "compiler.rs", "parser.rs", "lexer.rs", "interpreter.rs", "ast.rs", "token.rs", "value.rs", "library.rs", "functions.rs")
            New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "src") -Force | Out-Null # Ensure temp src dir exists
            foreach ($file in $srcFiles) {
                if (-not (Download-File -Uri "$RAZEN_REPO/src/$file" -OutFilePath (Join-Path $TMP_DIR "src\$file") -Description "src/$file")) { $downloadSuccess = $false }
            }
            
            # Download function files
            Write-ColorOutput "    Downloading function files..." "Yellow"
            $functionFiles = @("arrlib.rs", "mathlib.rs", "strlib.rs", "randomlib.rs", "filelib.rs", "jsonlib.rs", "boltlib.rs", "seedlib.rs", "colorlib.rs", "cryptolib.rs", "regexlib.rs", "uuidlib.rs", "oslib.rs", "validationlib.rs", "systemlib.rs", "boxutillib.rs", "loglib.rs", "htlib.rs", "netlib.rs", "timelib.rs", "color.rs")
            New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "src\functions") -Force | Out-Null # Ensure temp src/functions dir exists
            foreach ($file in $functionFiles) {
                if (-not (Download-File -Uri "$RAZEN_REPO/src/functions/$file" -OutFilePath (Join-Path $TMP_DIR "src\functions\$file") -Description "src/functions/$file")) { $downloadSuccess = $false }
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
            $scriptsToDownload = @("razen", "razen-debug", "razen-test", "razen-run", "razen-update", "razen-help", "razen-extension", "razen-docs", "razen-autogen", "razen-run-debug")
            New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "scripts") -Force | Out-Null # Ensure temp scripts dir exists
            foreach ($script in $scriptsToDownload) {
                 if (-not (Download-File -Uri "$RAZEN_REPO/scripts/$script" -OutFilePath (Join-Path $TMP_DIR "scripts\$script") -Description "scripts/$script")) {
                    Write-ColorOutput "    ⚠ Creating empty scripts/$script as fallback." "Yellow"
                    New-Item -ItemType File -Path (Join-Path $TMP_DIR "scripts\$script") -Force | Out-Null
                    # Continue even if download fails, with empty file
                 }
            }
            
            # Download extension files
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
    
    # Create Cargo.toml if it doesn't exist
    if (-not (Test-Path "$TMP_DIR\Cargo.toml")) {
        Write-ColorOutput "Cargo.toml not found. Creating a default one..." "Yellow"
        Create-DefaultCargoToml -TargetFile "$TMP_DIR\Cargo.toml"
    }
    
    # Verify directory structure
    Verify-DirectoryStructure -TargetDir $TMP_DIR
}

# Copy downloaded files from temporary directory to installation directory
Write-ColorOutput "Copying files to installation directory..." "Yellow"
try {
    # Copy all files from temp to installation directory
    Copy-Item -Path "$TMP_DIR\*" -Destination $installDir -Recurse -Force
    Write-ColorOutput "  ✓ Files copied successfully to $installDir" "Green"
    
    # Set proper permissions for script files
    Write-ColorOutput "Setting proper permissions for script files..." "Yellow"
    try {
        $scriptFiles = Get-ChildItem -Path "$installDir\scripts" -File -ErrorAction SilentlyContinue
        foreach ($script in $scriptFiles) {
            # In Windows, we don't need to set executable permissions like in Linux/macOS,
            # but we should ensure the files are not read-only
            if (Test-Path $script.FullName) {
                Set-ItemProperty -Path $script.FullName -Name IsReadOnly -Value $false
                Write-ColorOutput "  ✓ Set permissions for $($script.Name)" "Green"
            }
        }
        Write-ColorOutput "  ✓ All script permissions set successfully" "Green"
    } catch {
        Write-ColorOutput "  ✗ Warning: Could not set permissions for some script files" "Yellow"
        Write-ColorOutput "    Error: $($_.Exception.Message)" "Yellow"
        # Continue installation despite permission issues
    }
} catch {
    Handle-Error -ErrorMessage "Failed to copy files to installation directory" -RecoveryHint "Check permissions and try again"
}

# Check if Rust is installed and build the compiler
Write-ColorOutput "Checking for Rust installation..." "Yellow"
if (Test-RustInstalled) {
    Write-ColorOutput "  ✓ Rust is installed" "Green"
    
    # Build the Razen compiler
    Write-ColorOutput "Building Razen compiler..." "Yellow"
    try {
        # Change to the installation directory
        Push-Location $installDir
        
        # Run cargo build
        $buildOutput = & cargo build 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✓ Razen compiler built successfully" "Green"
        } else {
            Write-ColorOutput "  ✗ Failed to build Razen compiler" "Red"
            Write-ColorOutput "Build output:" "Red"
            Write-ColorOutput $buildOutput "Red"
            Write-ColorOutput "You may need to build the compiler manually later." "Yellow"
        }
        
        # Return to previous directory
        Pop-Location
    } catch {
        Write-ColorOutput "  ✗ Error during build process: $($_.Exception.Message)" "Red"
        Write-ColorOutput "You may need to build the compiler manually later." "Yellow"
    }
} else {
    Write-ColorOutput "  ✗ Rust is not installed" "Yellow"
    
    # Ask if the user wants to install Rust
    Write-ColorOutput "Rust is required to build the Razen compiler." "Yellow"
    Write-ColorOutput "Do you want to install Rust now? (y/n)" "Cyan"
    $installRust = Read-Host
    
    if ($installRust -eq "y" -or $installRust -eq "Y") {
        # Install Rust
        if (Install-Rust) {
            Write-ColorOutput "  ✓ Rust installed successfully" "Green"
            
            # Build the Razen compiler
            Write-ColorOutput "Building Razen compiler..." "Yellow"
            try {
                # Change to the installation directory
                Push-Location $installDir
                
                # Run cargo build
                $buildOutput = & cargo build 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "  ✓ Razen compiler built successfully" "Green"
                } else {
                    Write-ColorOutput "  ✗ Failed to build Razen compiler" "Red"
                    Write-ColorOutput "Build output:" "Red"
                    Write-ColorOutput $buildOutput "Red"
                    Write-ColorOutput "You may need to build the compiler manually later." "Yellow"
                }
                
                # Return to previous directory
                Pop-Location
            } catch {
                Write-ColorOutput "  ✗ Error during build process: $($_.Exception.Message)" "Red"
                Write-ColorOutput "You may need to build the compiler manually later." "Yellow"
            }
        } else {
            Write-ColorOutput "  ✗ Failed to install Rust" "Red"
            Write-ColorOutput "Please install Rust manually from https://www.rust-lang.org/tools/install" "Yellow"
            Write-ColorOutput "After installing Rust, you can build the Razen compiler by running 'cargo build' in the $installDir directory." "Yellow"
        }
    } else {
        Write-ColorOutput "Skipping Rust installation." "Yellow"
        Write-ColorOutput "You will need to install Rust manually from https://www.rust-lang.org/tools/install" "Yellow"
        Write-ColorOutput "After installing Rust, you can build the Razen compiler by running 'cargo build' in the $installDir directory." "Yellow"
    }
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