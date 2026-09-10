# DEMO STUB - echoes only.
#
# Replace with your real hardening content. The two realistic options:
#   1. provisioner "ansible" pointed at your existing hardening role
#   2. PowerShell DSC / LGPO applying a CIS or DISA STIG GPO backup
#
# Either way it runs HERE, once per image, instead of once per VM.

Write-Host "==> [4/5] Applying $env:CIS_PROFILE"

$controls = @(
    "1.1.x   Password and account lockout policy",
    "2.2.x   User rights assignment",
    "2.3.x   Security options (SMB signing, LSA protection)",
    "9.x     Windows Defender Firewall profiles",
    "17.x    Advanced audit policy configuration",
    "18.9.x  Administrative templates - LAPS, Credential Guard",
    "19.x    User configuration"
)

foreach ($c in $controls) {
    Write-Host "    [ok] $c"
}

Write-Host ""
Write-Host "    [ok] TLS 1.0/1.1 disabled, SMBv1 removed"
Write-Host "    [ok] Legacy ciphers removed from SCHANNEL"
Write-Host "    $env:CIS_PROFILE applied at BUILD time - idempotency is no longer"
Write-Host "    a concern because this runs exactly once, on a clean base image."
exit 0
