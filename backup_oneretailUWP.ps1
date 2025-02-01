# Define backup directory and log file
$BackupDirectory = "C:\RetailBackup"
$BackupFile = "$BackupDirectory\Onechannel.1RetailPOS_tamn31djrbc0w_archive.zip"
$LogFile = "$BackupDirectory\RetailBackup.log"

# Ensure backup directory exists
if (!(Test-Path $BackupDirectory)) {
    New-Item -ItemType Directory -Path $BackupDirectory -Force
}

# Get all user profiles (excluding system profiles)
$UserProfiles = Get-ChildItem -Path "C:\Users\" -Directory | Where-Object { $_.Name -notin @("Public", "Default", "Default User", "All Users", "Administrator") }

# Initialize error flag
$ErrorOccurred = $false

foreach ($User in $UserProfiles) {
    $RetailAppPath = "C:\Users\$($User.Name)\AppData\Local\Packages\Onechannel.1RetailPOS_tamn31djrbc0w\LocalState\*.db3"

    if (Test-Path $RetailAppPath) {
        try {
            # Attempt to compress the database files
            Compress-Archive -Path $RetailAppPath -DestinationPath $BackupFile -Force -ErrorAction Stop
            
            # Verify the archive was created successfully
            if (Test-Path $BackupFile) {
                # Only delete files if the archive exists
                Remove-Item -Path $RetailAppPath -Force -Recurse -ErrorAction Stop
                Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] SUCCESS: Backup completed and files deleted for user $($User.Name)."
            } else {
                $ErrorOccurred = $true
                Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] WARNING: Archive creation failed for user $($User.Name). Files not deleted."
            }
        } catch {
            $ErrorOccurred = $true
            Add-Content -Path $LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: Compression of POS DBs failed for user $($User.Name) - $_"
        }
    }
}

if ($ErrorOccurred) {
    Write-Host "One or more errors occurred. Check $LogFile for details."
} else {
    Write-Host "Backup and cleanup completed successfully."
}
