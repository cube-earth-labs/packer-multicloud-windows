# DEMO STUB - echoes only.
#
# The image is PREPARED for the domain, never joined to it. A sysprepped image
# that was domain-joined at build time carries one machine account that every
# clone then fights over. Correct pattern is offline domain join (djoin) with a
# per-VM blob handed in at first boot by Terraform user_data / customData.

Write-Host "==> [3/5] Domain join preparation for $env:AD_DOMAIN"
Write-Host "    [ok] DNS suffix search list pre-seeded: $env:AD_DOMAIN"
Write-Host "    [ok] Time source pointed at domain hierarchy"
Write-Host "    [ok] Root/issuing CA certificates imported to LocalMachine\Root"
Write-Host "    [ok] Offline-domain-join first-boot task registered"
Write-Host ""
Write-Host "    At deploy time Terraform supplies the djoin blob:"
Write-Host "      djoin.exe /requestODJ /loadfile C:\odj.txt /windowspath C:\Windows /localos"
Write-Host ""
Write-Host "    Image itself stays domain-agnostic and reusable across all OUs."
exit 0
