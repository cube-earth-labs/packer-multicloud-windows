# REAL - not a stub.
#
# Generalization is the one step that genuinely cannot be shared between
# clouds, which is exactly why the build block scopes it with `only`.
#
# On AWS, EC2Launch v2 owns sysprep. Calling Sysprep.exe directly would strip
# the EC2Launch configuration and the resulting AMI would boot with no password
# randomization, no drive initialization, and no user_data execution.

Write-Host "==> Generalizing for AWS (EC2Launch v2)"

$ec2Launch = "C:\Program Files\Amazon\EC2Launch\EC2Launch.exe"

if (-not (Test-Path $ec2Launch)) {
    Write-Error "EC2Launch v2 not found at $ec2Launch - is this a Server 2022 base AMI?"
    exit 1
}

Write-Host "    Handing off to EC2Launch sysprep; instance will shut down."
& $ec2Launch sysprep --shutdown
