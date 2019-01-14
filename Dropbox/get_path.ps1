#Grab Dropbox Path from config.bat and set $dropbox variable

$dropbox = Get-Content $PSScriptRoot\config.bat `
          | ? { $_ -match "Dropbox_Path=\s*"} `
          | select -First 1 `
          | % { ($_ -split "=", 2)[1] }

# Set other Variables using $dropbox 

$input_csv = "$dropbox\test\Test.csv"
$master_csv = "$dropbox\test\Test-MASTER.csv"
$output_file = "$dropbox\test\Test.txt"


$this_dir = [io.path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$this_dir

$dropbox = Get-Content -Path "$([io.path]::GetDirectoryName($MyInvocation.MyCommand.Path))\config.bat" `
          | ? { $_ -match "Dropbox_Path=\s*"} `
          | select -First 1 `
          | % { ($_ -split "=", 2)[1] }

$dropbox
