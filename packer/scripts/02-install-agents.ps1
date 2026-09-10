# DEMO STUB - echoes only.
#
# This is the step that buys back the most time. Every agent installed here is
# an agent NOT installed post-provision, and therefore one fewer reason for the
# platform team to have to touch a VM after an app team asks for it.

Write-Host "==> [2/5] Baking agents into the image"

$agents = $env:AGENTS -split ","

foreach ($agent in $agents) {
    Write-Host "    installing $agent ..."
    Write-Host "      [ok] $agent installed, service set to Automatic (Delayed Start)"
}

Write-Host ""
Write-Host "    NOTE: agents are installed but NOT registered. Registration is"
Write-Host "          per-VM and must happen at first boot, or every VM cloned"
Write-Host "          from this image reports as the same host."
exit 0
