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

C:\Users\dk\scoop\apps\rclone-beta\current\rclone.exe --config C:\Lab_Data\configurations-private\rclone.conf check "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents" "Blomp-Banee-Gmail-Drive:WhatsApp Backup Contents" --transfers 4 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --verbose --stats 1s --stats-file-name-length 0 --differ C:\Temp_Data\Avita-WhatsApp-Backup-Contents-differ.txt --missing-on-dst C:\Temp_Data\Avita-WhatsApp-Backup-Contents-Missing-On-Cloud.txt
