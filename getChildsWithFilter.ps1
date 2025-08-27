#!pwsh
Get-ChildItem -Path "C:\Temp_Data\" -Filter "Avita-WhatsApp-Backup-Contents-*" |
Foreach-Object {
    if ($_.Length -gt 0)
    {
        $_.FullName
    }
}
