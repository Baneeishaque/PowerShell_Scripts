$pageContent = Invoke-WebRequest -Uri "https://plugins.jetbrains.com/docs/intellij/android-studio-releases-list.html"
$intermediateContent = $pageContent.Content.Substring($pageContent.Content.IndexOf("Beta-darkred"))
$intermediateContent = $intermediateContent.Substring($intermediateContent.IndexOf("<span"))
$intermediateContent = $intermediateContent.Substring($intermediateContent.IndexOf(">")+1) | Out-File -FilePath C:\Temp_Data\test.txt
