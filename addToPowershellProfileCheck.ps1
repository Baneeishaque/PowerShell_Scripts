$dir = "test"
$PROFILE2 = Test.txt
Add-Content -Path $PROFILE2 -Value "`n# rbenv for Windows"
Add-Content -Path $PROFILE2 -Value "`$env:RBENV_ROOT = `"$dir\rbenv_root`""
Add-Content -Path $PROFILE2 -Value "& `"`$env:RBENV_ROOT\rbenv\bin\rbenv.ps1`" init"
