$ServiceName=”sshd”
if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
Stop-Service $ServiceName
Set-Service $ServiceName -StartupType Disabled
echo “The service $ServiceName has been disabled.”
}
else {
echo “The service $ServiceName is not installed.”
}