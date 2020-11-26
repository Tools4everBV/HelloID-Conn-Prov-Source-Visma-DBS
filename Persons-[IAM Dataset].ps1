Write-Verbose -Verbose "[Persons] import started"

# Load CSV files
$csvDirectory = 'D:\HelloID\Uitwisselmap'
$persons = Import-CSV -Path "$csvDirectory\T4E_IAM_Person.csv"

$contracts = Import-CSV -Path "$csvDirectory\T4E_IAM_Contracts.csv" 
$csvOrganizationalFunctions = Import-CSV -Path "$csvDirectory\T4E_IAM_OrganizationalFunctions.csv" | Group-Object functionID -AsHashTable 
$csvOrganizations = Import-CSV -Path "$csvDirectory\T4E_IAM_Organizations.csv" | Group-Object companyID -AsHashTable

# add contracts, externalId and displayName properties to persons
$persons | Add-Member -MemberType NoteProperty -Name "Contracts" -Value $null -Force
$persons | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
$persons | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force

# add function and organization description to contracts
$contracts | Add-Member -MemberType NoteProperty -Name "FunctionName" -Value $null -Force
$contracts | Add-Member -MemberType NoteProperty -Name "OrganizationName" -Value $null -Force

# Enrich contracts with function and organization data
$contracts | ForEach-Object {

    # Function
    $personFunction = $csvOrganizationalFunctions[$_.functionID]
    if ($personFunction.count -eq 1) {
        $_.FunctionName = $personFunction.name
    }

    #Organization
    $personOrganization = $csvOrganizations[$_.bed_id]
    if ($personOrganization.count -eq 1) {
        $_.OrganizationName = $personOrganization.companyName
    }
}

# group contracts on combined_id
$contracts = $contracts | Group-Object -Property combined_id -AsHashTable

# Add the enriched contracts to the person records
$persons | ForEach-Object {
    $_.ExternalId = $_.combined_id
    $_.DisplayName = $_.combined_id

    $personContracts = $contracts[$_.combined_id]
    if ($null -ne $personContracts) {
        $_.Contracts = $personContracts
    }
}

# Make sure persons are unique
$persons = $persons | Sort-Object ExternalId -Unique

Write-Verbose -Verbose "[Persons] Import completed"
Write-Verbose -Verbose "[Persons] Exporting data to HelloID"

# Output the json
foreach ($person in $persons) {
    $json = $person | ConvertTo-Json -Depth 3
    Write-Output $json
}

Write-Verbose -Verbose "[Persons] Exported data to HelloID"