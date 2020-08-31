Function Get-ManagerId {
    param ([String]$ManagerLoginName)

    $managerId = $managers | Where-Object { $_.ManagerLoginName -eq $ManagerLoginName };
    return $managerId.ManagerId;
}

$departments = Import-CSV -Path "C:\Program Files\Tools4ever\Visma\visma.csv" | Where { ($_.werknemersgroep -ne 'Vrijwilliger' -and $_.werknemersgroep -ne 'Artiest') }
$departmentList = [System.Collections.ArrayList]@()

$persons = Import-CSV -Path "C:\Program Files\Tools4ever\Visma\visma.csv" | Where { ($_.werknemersgroep -ne 'Vrijwilliger' -and $_.werknemersgroep -ne 'Artiest') }
$personList = [System.Collections.ArrayList]@()

$managers = $persons | Where-Object { $_.ManagerLoginName -ne '' } | Select-Object -Property ManagerLoginName -Unique;
$managersList = $persons | Select-Object -Property LoginName, wns_id -Unique;

Foreach ($manager in $managers) {
    Foreach ($managerLookup in $managersList) {
        if ($managerLookup.LoginName -match $manager.ManagerLoginName) {
            $managerUid = $managerLookup.wns_id;
            $manager | Add-Member -Name "ManagerId" -MemberType NoteProperty -Value $managerUid;
        }
    }
}

$list = $departments | Select-Object -Property afd_nr, afd_naam, ManagerLoginName -Unique ;
Foreach ($department in $list) {    
    $managerId = Get-ManagerId $department.ManagerLoginName;     
    
    $departmentObject = [PSCustomObject]@{
        ExternalId = $department.afd_nr;
        DisplayName = $department.afd_naam;
        Name = $department.afd_naam;
        ManagerExternalId = $managerId;
    }    
    $departmentList.Add($departmentObject) | Out-Null;          
}

Write-Output $departmentList | ConvertTo-Json -Depth 10;