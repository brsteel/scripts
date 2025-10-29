<#
backend-remediation.ps1
Purpose: Ensure each backend Linux VM (identity, operations, shared services) listens on TCP 443 and responds 200 on /healthz and /. Designed for Application Gateway HTTPS backend pool.
Approach: Uses Azure VM RunCommand (RunShellScript) to install Python + gunicorn, generate a self-signed cert, deploy a Flask app with /healthz and / endpoints, and create/enable a systemd service.
NOTE: If Application Gateway requires trusted backend cert validation, import the generated certificate (or use a trusted CA) into the gateway backend HTTP settings as a trustedRootCertificate. Self-signed may fail health probe if validation is enabled.
Prereqs: az CLI logged in; user has access to all three subscriptions. PowerShell 5.1+.
Usage: powershell -ExecutionPolicy Bypass -File ./backend-remediation.ps1 [-WhatIf]
#>
param(
  [switch]$WhatIf,
  [int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'

# Backend inventory (from earlier session)
$Backends = @(
  @{ Subscription = '6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24'; ResourceGroup = 'mlz-ops-rg'; VmName = 'ops-backend-01'; ExpectedIP = '10.0.131.18' }
  @{ Subscription = 'd9cb6670-f9bf-416f-aa7b-2d6936edcaeb'; ResourceGroup = 'mlz-identity-rg'; VmName = 'identity-backend-01'; ExpectedIP = '10.0.130.8' }
  @{ Subscription = '3a8f043c-c15c-4a67-9410-a585a85f2109'; ResourceGroup = 'mlz-shared-rg'; VmName = 'shared-backend-01'; ExpectedIP = '10.0.132.8' }
)

# Bash payload; minimal, idempotent.
$RemediationScript = @'
#!/bin/bash
set -euo pipefail
log() { echo "[remediate] $1"; }
log "Starting remediation $(date)"

# Detect distro family (Debian/Ubuntu assumed; extend if needed)
if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y || true
  apt-get install -y python3 python3-pip openssl || true
else
  log "Unsupported distro (needs apt-get)."; exit 1
fi

python3 -m pip install --upgrade pip || true
python3 -m pip install --no-cache-dir flask gunicorn || true

mkdir -p /opt/backend
if [ ! -f /etc/ssl/backend.key ] || [ ! -f /etc/ssl/backend.crt ]; then
  log "Generating self-signed certificate"
  openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/backend.key -out /etc/ssl/backend.crt -subj "/CN=$(hostname)-backend" -days 365 || true
  chmod 600 /etc/ssl/backend.key
fi

cat > /opt/backend/app.py <<'APP'
from flask import Flask
app = Flask(__name__)
@app.route('/healthz')
def healthz():
    return 'ok', 200
@app.route('/')
def root():
    return 'backend', 200
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=443, ssl_context=('/etc/ssl/backend.crt','/etc/ssl/backend.key'))
APP

cat > /opt/backend/start.sh <<'ST'
#!/bin/bash
exec /usr/bin/python3 -m gunicorn app:app --certfile /etc/ssl/backend.crt --keyfile /etc/ssl/backend.key --bind 0.0.0.0:443 --workers 2 --access-logfile - --error-logfile -
ST
chmod +x /opt/backend/start.sh

cat > /etc/systemd/system/backend.service <<'UNIT'
[Unit]
Description=Backend HTTPS Flask Service
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/opt/backend
ExecStart=/opt/backend/start.sh
Restart=always
RestartSec=5
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable backend.service || true
systemctl restart backend.service || true
sleep 4
log "Status snippet:"
systemctl status backend.service --no-pager | head -n 25 || true
log "Listening sockets (443):"
ss -tnlp | grep ':443' || true
log "Probe /healthz locally:"
curl -sk --max-time 5 https://localhost/healthz || true
log "Done"
'@

function Invoke-BackendRemediation {
  param($Entry)
  Write-Host "==== Remediating $($Entry.VmName) ($($Entry.ExpectedIP)) in subscription $($Entry.Subscription) ====" -ForegroundColor Cyan
  az account set --subscription $Entry.Subscription
  if ($WhatIf) { Write-Host "[WhatIf] Would run remediation script on $($Entry.VmName)"; return }
  $result = az vm run-command invoke \
    --resource-group $($Entry.ResourceGroup) \
    --name $($Entry.VmName) \
    --command-id RunShellScript \
    --scripts "$RemediationScript" \
    --query "value[0].message" -o tsv
  Write-Host $result
}

foreach ($b in $Backends) {
  try { Invoke-BackendRemediation -Entry $b } catch { Write-Warning "Failed remediation for $($b.VmName): $($_.Exception.Message)" }
}

Write-Host "All remediation attempts completed." -ForegroundColor Green<#
backend-remediation.ps1
Remediates backend Linux VMs to ensure an HTTPS Flask service answers on port 443 at /healthz.
Assumes cross-subscription spokes; fill in the $Backends array with actual subscription / RG / VM names.
Usage (PowerShell 5.1 or 7):
  pwsh ./backend-remediation.ps1 -WhatIf:$false
Requires: az CLI logged in to all target subscriptions (run: az login --scope https://management.core.usgovcloudapi.net//.default)
#>
param(
  [switch]$WhatIf,
  [int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'

$Backends = @(
  # SAMPLE ENTRIES - replace with real values
  @{ Subscription = 'CET-FFX-BRSTEEL-MLZOPS'; ResourceGroup = 'mlz-ops-rg'; VmName = 'ops-backend-01'; ExpectedIP = '10.0.131.18' }
  @{ Subscription = 'CET-FFX-BRSTEEL-MLZIDENTITY'; ResourceGroup = 'mlz-identity-rg'; VmName = 'identity-backend-01'; ExpectedIP = '10.0.130.8' }
  @{ Subscription = 'CET-FFX-BRSTEEL-MLZSHAREDSERVICES'; ResourceGroup = 'mlz-shared-rg'; VmName = 'shared-backend-01'; ExpectedIP = '10.0.132.8' }
)

$RemediationScript = @"
#!/bin/bash
set -euo pipefail
log() { echo "[remediate] $1"; }
log "Starting remediation $(date)"

if ! command -v python3 >/dev/null 2>&1; then
  log "Installing python3"
  apt-get update -y || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip openssl || true
fi

# Ensure pip & packages
python3 -m pip install --upgrade pip || true
python3 -m pip install --no-cache-dir flask gunicorn || true

mkdir -p /opt/backend
if [ ! -f /etc/ssl/backend.crt ] || [ ! -f /etc/ssl/backend.key ]; then
  log "Generating self-signed certificate"
  openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/backend.key -out /etc/ssl/backend.crt -subj "/CN=$(hostname)-backend" -days 365 || true
fi

# App code
cat > /opt/backend/app.py <<'APP'
from flask import Flask
app = Flask(__name__)
@app.route('/healthz')
def healthz():
    return 'ok', 200
@app.route('/')
def root():
    return 'backend', 200
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=443, ssl_context=('/etc/ssl/backend.crt','/etc/ssl/backend.key'))
APP

# Systemd unit using gunicorn for robustness
cat > /opt/backend/start.sh <<'ST'
#!/bin/bash
exec /usr/bin/python3 -m gunicorn app:app --certfile /etc/ssl/backend.crt --keyfile /etc/ssl/backend.key --bind 0.0.0.0:443 --workers 2 --access-logfile - --error-logfile -
ST
chmod +x /opt/backend/start.sh

cat > /etc/systemd/system/backend.service <<'UNIT'
[Unit]
Description=Backend HTTPS Flask Service
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/opt/backend
ExecStart=/opt/backend/start.sh
Restart=always
RestartSec=5
# Hardening
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable backend.service || true
systemctl restart backend.service || true
sleep 3
log "Systemd status:"
systemctl status backend.service --no-pager | head -n 30 || true
log "Listening sockets on 443:"
ss -tnlp | grep :443 || true
log "Curl localhost/healthz:"
curl -vk --max-time 5 https://localhost/healthz || true
log "Done"
"@

function Invoke-BackendRemediation {
  param($Entry)
  Write-Host "==== Remediating ${($Entry.VmName)} in subscription ${($Entry.Subscription)} ====" -ForegroundColor Cyan
  az account set --subscription $Entry.Subscription
  if ($WhatIf) { Write-Host "[WhatIf] Would run remediation script on $($Entry.VmName)"; return }
  $result = az vm run-command invoke `
      --resource-group $Entry.ResourceGroup `
      --name $Entry.VmName `
      --command-id RunShellScript `
      --scripts $RemediationScript `
      --query "value[0].message" -o tsv
  Write-Host $result
}

foreach ($b in $Backends) {
  try { Invoke-BackendRemediation -Entry $b } catch { Write-Warning "Failed: $($_.Exception.Message)" }
}

Write-Host "All remediation attempts completed." -ForegroundColor Green
