#Set my hostname based on my internal IP address
$instanceName = (((Invoke-WebRequest -UseBasicParsing -Uri http://169.254.169.254/latest/meta-data/hostname).Content).split(".")[0]).replace("ip-172-31","TCG")

#Change the hostname in the unattend.xml file
$filePath = "C:\Windows\Panther\Unattend.xml"
$AnswerFile = [xml](Get-Content -Path $filePath)
$ns = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
$ns.AddNamespace("ns", $AnswerFile.DocumentElement.NamespaceURI)
$ComputerName = $AnswerFile.SelectSingleNode('/ns:unattend/ns:settings[@pass="specialize"]/ns:component[@name="Microsoft-Windows-Shell-Setup"]/ns:ComputerName', $ns)
$ComputerName.InnerText = $InstanceName
$AnswerFile.Save($filePath)

#Start the OOBE
Start-Process C:\windows\system32\oobe\windeploy.exe -Wait
