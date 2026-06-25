# import.ps1 - Pull workflows and ensure container setup

. .\variables.ps1
$repoPath = $repoLoc + "\workflows"
$exportPath = $repoLoc

# Derive network and volume names from container name
$NetworkName = "${containerName}_network"
$VolumeName  = "${containerName}_volume"

if ($useGit) {
    Write-Host "Updating workflows from Git..."
    Set-Location $repoLoc
    git pull
    Write-Host "Git repository updated."
}

# Ensure Docker network exists
if (-not (docker network ls --format '{{.Name}}' | Select-String -Pattern $NetworkName)) {
    Write-Host "Creating Docker network $NetworkName..."
    docker network create --opt com.docker.network.enable_ipv6=false $NetworkName
}

# Ensure Docker volume exists
if (-not (docker volume ls --format '{{.Name}}' | Select-String -Pattern $VolumeName)) {
    Write-Host "Creating Docker volume $VolumeName..."
    docker volume create $VolumeName
}

# Ensure container exists and is running
if (-not (docker ps -a -q -f name=$containerName)) {
    Write-Host "Creating and starting n8n container..."
    docker run -d `
      --name $containerName `
      --network $NetworkName `
      -p 5678:5678 `
      -v ${VolumeName}:/home/node/.n8n `
      -e GENERIC_TIMEZONE="Asia/Manila" `
      -e TZ="Asia/Manila" `
      -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true `
      -e N8N_RUNNERS_ENABLED=true `
      -e NODE_OPTIONS="--dns-result-order=ipv4first" `
      --dns 8.8.8.8 `
      --dns 8.8.4.4 `
      docker.n8n.io/n8nio/n8n
}
elseif (-not (docker ps -q -f name=$containerName)) {
    Write-Host "Starting existing n8n container..."
    docker start $containerName
}

# Ensure backups folder exists in container
docker exec $containerName mkdir -p /home/node/.n8n/backups

# Clear old files in container
docker exec $containerName sh -c "rm -f /home/node/.n8n/backups/*.json"

# Copy workflow JSONs into container
docker cp "$repoPath" "${containerName}:/home/node/.n8n/backups/"

# Import workflows into n8n
docker exec $containerName n8n import:workflow --input=/home/node/.n8n/backups/workflows --separate

Write-Host "Workflows imported to n8n successfully."

pause
