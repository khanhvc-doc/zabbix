$csvPath = ".\Devices_List.csv"
$outputPath = ".\00_hosts_snmp.yaml"

$devices = Import-Csv $csvPath

# Ghi header
@"
zabbix_export:
  version: '7.4'
  host_groups:
    - uuid: e0e17488965f481488f670e5767a9057
      name: 'vck_SNMP_v2_Host Groups'
  hosts:
"@ | Out-File -Encoding UTF8 $outputPath

# Append từng host (tránh lỗi indent)
foreach ($d in $devices) {

    $ip = $d.IP.Trim()
    $desc = ($d.Descriptions -replace ' ', '_').Trim()
    $location = ($d.Location -replace ' ', '_').Trim()
    
    # cấu trúc tên chỉnh chổ này.
    $hostName = "SNMP_ver2_${location}_${ip}_${desc}"

    @"
    - host: '$hostName'
      name: '$hostName'
      templates:
        - name: 'vck_SNMP_v2_Template'
      groups:
        - name: 'vck_SNMP_v2_Host Groups'
      interfaces:
        - type: SNMP
          ip: '$ip'
          port: '161'
          details:
            community: '{`$SNMP_COMMUNITY}'
          interface_ref: if1
      macros:
        - macro: '{`$SNMP_COMMUNITY}'
          value: 'KhanhVC_RO'

"@ | Out-File -Append -Encoding UTF8 $outputPath
}

Write-Host "Done!"