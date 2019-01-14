$result="SELECT * FROM ``ticket`` WHERE ``agent`` IN ("
$i=0
foreach($line in Get-Content '.\read text file sample.txt') {
    
    # if($line -match $regex){
        # Work here
    # }

    if($i -eq 0)
    {
        $result="$result'$line'"
    }
    else {
        $result="$result,'$line'"        
    }
    # Write-Host $line

    $i++
}

$result="$result,'ktn') ORDER BY ``insertion_date``;"

Write-Host $result