#!pwsh
Get-ChildItem "C:\Lab_Data\To_Upload\WhatsApp Last Backup Contents" |

Foreach-Object {

    # $_.FullName
    $_.BaseName

}
