# sync.ps1 - Export n8n workflows and push to GitHub

Write-Host "toGIT.ps1 pushes to current branch"

. .\variables.ps1
$repoPath = $repoLoc + "\workflows"
$exportPath = $repoLoc

# Fix permissions on backups folder
docker exec --user root $containerName chown -R node:node /home/node/.n8n/backups/

# Clear old exports in container
docker exec $containerName sh -c "rm -f /home/node/.n8n/backups/workflows/*.json"

# Export workflows into container
docker exec $containerName n8n export:workflow --all --backup --output=/home/node/.n8n/backups/workflows/

# Clear local repoPath before copying new files
Remove-Item -Path "$repoPath\*" -Recurse -Force

# Copy out of container to local workflows folder
docker cp "${containerName}:/home/node/.n8n/backups/workflows/." $repoPath

# Clean credentials from exported workflows
$workflowFiles = Get-ChildItem -Path $repoPath -Filter *.json
foreach ($file in $workflowFiles) {
    $content = Get-Content $file.FullName -Raw
    $content = $content.TrimStart([char]0xFEFF) # remove BOM if present
    $json = $content | ConvertFrom-Json

    # Build a clean object with only safe fields
    $clean = [PSCustomObject]@{
        id          = $json.id
        name        = $json.name
        description = $json.description
        nodes       = $json.nodes
        connections = $json.connections
        settings    = $json.settings
        tags        = $json.tags
    }

    # Strip credentials from nodes
    foreach ($node in $clean.nodes) {
        if ($node.PSObject.Properties.Name -contains "credentials") {
            $node.PSObject.Properties.Remove("credentials")
        }
    }

    # Save back without BOM
    $clean | ConvertTo-Json -Depth 100 | Out-File $file.FullName -Encoding utf8
}
Write-Host "Workflows cleaned: only essential fields retained."

# Commit and push
Set-Location $exportPath
git add .
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "($deviceName) chore: workflow sync $timestamp"

$branch = git rev-parse --abbrev-ref HEAD
git push -u origin $branch

Write-Host "Pushed changes to branch $branch"
pause