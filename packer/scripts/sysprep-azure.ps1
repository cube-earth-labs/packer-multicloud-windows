# REAL - not a stub.
#
# Azure has no equivalent of EC2Launch, so sysprep is invoked directly and we
# poll the registry until generalization completes. Packer then calls the ARM
# API to deallocate + mark the VM generalized before capturing.
#
# /quit (not /shutdown) - Packer needs the WinRM session to survive long enough
# to observe IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE.

Write-Host "==> Generalizing for Azure (Sysprep + generalize)"

& "$env:SystemRoot\System32\Sysprep\Sysprep.exe" /oobe /generalize /mode:vm /quiet /quit

$stateKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"

while ($true) {
    $imageState = (Get-ItemProperty $stateKey).ImageState
    Write-Host "    ImageState = $imageState"

    if ($imageState -eq "IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE") {
        break
    }
    Start-Sleep -Seconds 10
}

Write-Host "    Generalized. Packer will now deallocate and capture."
