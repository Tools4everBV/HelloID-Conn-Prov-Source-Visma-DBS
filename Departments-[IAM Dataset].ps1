Write-Verbose -Verbose "[Departments] Import started"

$csvDirectory = 'D:\HelloID\Uitwisselmap'
$csvDepartments = Import-CSV -Path "$csvDirectory\T4E_IAM_OrganizationalUnits.csv"

$departments = [System.Collections.Generic.List[PscustomObject]]::new() 

Foreach ($csvDepartment  in $csvDepartments) {
    $department = [PscustomObject]@{
        ExternalId = $csvDepartment.OrgUnitID
        DisplayName = $csvDepartment.name
        Name = $csvDepartment.name
        ParentExternalId = $csvDepartment.orgUnitParentID
        ManagerExternalId = $csvDepartment.manager_emp_id
    }
    [void]$departments.add($department)
}
$departments = $departments | Sort-Object ExternalId -Unique

$json = $departments | ConvertTo-Json -Depth 3
Write-Verbose -Verbose "[Departments] Exporting data to HelloID"
Write-Output $json
Write-Verbose -Verbose "[Departments] Exported data to HelloID"