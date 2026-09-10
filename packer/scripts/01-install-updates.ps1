# DEMO STUB - echoes only. Swap the body for your real update mechanism
# (PSWindowsUpdate, WSUS, or an Ansible role called via the ansible provisioner).

Write-Host "==> [1/5] Windows Update"
Write-Host "    Real build would: Install-Module PSWindowsUpdate -Force"
Write-Host "    Real build would: Get-WUInstall -AcceptAll -IgnoreReboot"

foreach ($kb in @("KB5034123", "KB5033920", "KB5032190")) {
    Write-Host "    [ok] applied $kb"
}

Write-Host "    Patch level baked into image. Post-provision patching window: eliminated."
exit 0
