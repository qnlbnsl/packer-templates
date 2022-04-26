Write-Host "Installing packages from choco"
choco install vcredist-all --version 1.0.1 -y
choco install directx --version 9.29.1974.20210222 -y
choco install 7zip --version 21.7 -y
# choco install virtio-drivers -y
choco install nomachine -y
choco install pwsh -y
Write-Host "Install Completed"
