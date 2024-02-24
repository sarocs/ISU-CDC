$ip = Read-Host "Wazuh manager IP"
$name = Read-Host "Wazuh agent name"
$version = Read-Host "Wazuh agent version"

Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-$version.msi" -OutFile ${env.tmp}\wazuh-agent; msiexec.exe /i ${env.tmp}\wazuh-agent /q WAZUH_MANAGER="$ip" WAZUH_AGENT_NAME="$name" WAZUH_REGISTRATION_SERVER="$ip" 

# Enable PowerShell logging
$basePath = @(
    'HKLM:\Software\Policies\Microsoft\Windows'
    'PowerShell\ScriptBlockLogging'
) -join '\'

if (-not (Test-Path $basePath)) {
    $null = New-Item $basePath -Force
}

Set-ItemProperty $basePath -Name EnableScriptBlockLogging -Value "1"

# Install Sysmon
Invoke-WebRequest https://download.sysinternals.com/files/Sysmon.zip -OutFile Sysmon.zip
Expand-Archive .\Sysmon.zip -DestinationPath 'C:\Program Files\Sysmon'
Invoke-WebRequest https://wazuh.com/resources/blog/detecting-process-injection-with-wazuh/sysmonconfig.xml -OutFile 'C:\Program Files\Sysmon\sysmonconfig.xml'
& 'C:\Program Files\Sysmon\Sysmon64.exe' -accepteula -i 'C:\Program Files\Sysmon\sysmonconfig.xml'

# Enable remote commands
Add-Content -Path 'C:\Program Files (x86)\ossec-agent\local_internal_options.conf' -Value 'wazuh_command.remote_commands=1'
# Add-Content -Path 'C:\Program Files (x86)\ossec-agent\local_internal_options.conf' -Value 'logcollector.remote_commands=1'

# Move scripts
Move-Item -Path .\tasklist.bat -Destination C:\tasklist.bat
Move-Item -Path .\net_info.bat -Destination C:\net_info.bat

NET START WazuhSvc

Set-Service -Name WazuhSvc -StartupType Automatic