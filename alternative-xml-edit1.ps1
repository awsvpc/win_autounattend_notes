  $sysprepFile = ('{{0}}\Amazon\Ec2ConfigService\sysprep2008.xml' -f $env:ProgramFiles)
  [xml] $xml = Get-Content($sysprepFile)
  $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
  $ns.AddNamespace("u", 'urn:schemas-microsoft-com:unattend')
  $component = $xml.SelectSingleNode('//u:settings[@pass=specialize]/u:component[@name=Microsoft-Windows-Shell-Setup]', $ns)
  if (-not $component.ComputerName) {{
    $computerNameElement = $xml.CreateElement("ComputerName")
    $computerNameElement.value = "{hostname}"
    $component.AppendChild($computerNameElement)
    Write-Log -message ('computer name inserted to: {{0}}' -f $sysprepFile) -severity 'DEBUG'
  }} else {{
    $component.ComputerName.value = "{hostname}"
    Write-Log -message ('computer name updated in: {{0}}' -f $sysprepFile) -severity 'DEBUG'
  }}
