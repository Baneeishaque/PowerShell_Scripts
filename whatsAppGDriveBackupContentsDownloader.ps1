Set-Location C:\Lab_Data\whapa
.\.venv\Scripts\Activate.ps1

git checkout hajara
python "C:\Lab_Data\whapa\libs\whagodri.py" -s -o "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents\\" --no_parallel
git checkout banee
python "C:\Lab_Data\whapa\libs\whagodri.py" -s -o "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents\\" --no_parallel
git checkout ismail
python "C:\Lab_Data\whapa\libs\whagodri.py" -s -o "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents\\" --no_parallel
git checkout jusaira
python "C:\Lab_Data\whapa\libs\whagodri.py" -s -o "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents\\" --no_parallel
git checkout nasaru
python "C:\Lab_Data\whapa\libs\whagodri.py" -s -o "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents\\" --no_parallel
git checkout master

Get-ChildItem "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents" |
Foreach-Object {

    C:\Users\dk\scoop\apps\rclone-beta\current\rclone.exe --config C:\Lab_Data\configurations-private\rclone.conf check "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents\$($_.BaseName)\files\Databases\" "Blomp-Banee-Gmail-Drive:WhatsApp Backup Contents\$($_.BaseName)\files\Databases\" --differ "C:\Temp_Data\Avita-WhatsApp-Backup-Contents-$($_.BaseName)-Databases-differ-with-cloud-storage.txt"
}

Get-ChildItem -Path "C:\Temp_Data\" -Filter "Avita-WhatsApp-Backup-Contents-*" |
Foreach-Object {
    if ($_.Length -eq 0)
    {
        Remove-Item $_.FullName
    }
}
