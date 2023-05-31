Get-Content C:\Temp_Data\persist_data_missing_on_cloud.txt | ForEach-Object {
    $_.Split("/")[0]
} | Sort-Object | Get-Unique
