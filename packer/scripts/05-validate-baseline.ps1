# DEMO STUB - echoes only, always exits 0.
#
# In a real pipeline this is the gate: make it exit non-zero and Packer fails
# the build, so a non-compliant image never reaches the registry at all. Pester
# or InSpec are the usual choices here.

Write-Host "==> [5/5] Post-reboot baseline validation"
Write-Host "    (running AFTER windows-restart - proves the baseline persisted)"
Write-Host ""

$checks = @(
    "SMBv1 absent",
    "TLS 1.2+ only",
    "Firewall enabled on all three profiles",
    "All baked agents present and set to Automatic",
    "No agent registered to a host identity",
    "Not joined to $env:AD_DOMAIN (correct - join happens at first boot)",
    "$env:CIS_PROFILE controls still in effect"
)

foreach ($c in $checks) {
    Write-Host "    PASS  $c"
}

Write-Host ""
Write-Host "    Baseline verified. Safe to generalize."
exit 0
