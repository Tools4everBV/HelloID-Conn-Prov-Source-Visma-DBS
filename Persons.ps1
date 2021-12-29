Function Get-ManagerId{
    param ([String]$ManagerLoginName)

    $managerId = $managers | Where-Object {$_.ManagerLoginName -eq $ManagerLoginName};

    return $managerId.ManagerId;
}

$persons = Import-CSV -Path "C:\Program Files\Tools4ever\Visma\visma.csv" | Where-Object {($_.werknemersgroep -ne 'Vrijwilliger' -and  $_.werknemersgroep -ne 'Artiest')}

$personList = [System.Collections.ArrayList]@()

$managers = $persons | Where-Object {$_.ManagerLoginName -ne ''} | Select-Object -Property ManagerLoginName -Unique;
$managersList = $persons | Select-Object -Property LoginName, wns_id -Unique;

Foreach ($manager in $managers)
{
    Foreach ($managerLookup in $managersList)
    {
        if($managerLookup.LoginName -match $manager.ManagerLoginName)
        {
            $managerUid = $managerLookup.wns_id;
            $manager | Add-Member -Name "ManagerId" -MemberType NoteProperty -Value $managerUid;
        }
    }
}



Foreach ($person in $persons) {
    if($person.wns_id -eq $lastPerson)
    {
        $counter+= 1;
    }
    else
    {
        $counter = 0;
    }

    if ($person.UniqueID -notin $personList.UniqueID) {

        $personObject = $person | Select-Object -Property UniqueID, wns_id, bed_id, voorl, roepnaam, voorv, geboortenaam, voorvpartner, naampartner, k_naamgebruik, dat_geb, geslacht -Unique ;
        $externalID = "$($person.wns_id)".trim()
        $firstName = "$($person.roepnaam)".trim()
        $prefix = "$($person.voorv)".trim()
        $lastName = "$($person.geboortenaam)".trim()
        $partnerPrefix = "$($person.voorvpartner)".trim()
        $partnerLastname = "$($person.naampartner)".trim()
        
        $nameConvention = $person.k_naamgebruik.Code
        switch($nameConvention){
            'E' {
                # Birthname
                $displayName = $firstName
    
                if(-not[String]::IsNullOrEmpty($prefix)){ $displayName = $displayName + " " + $prefix }
                $displayName = $displayName + " " + $lastName
    
                $displayName = $displayName + " " + "($externalID)"
            }
            'B' {
                # Partnername - Birthname
                $displayName = $firstName
    
                if(-not[String]::IsNullOrEmpty($partnerPrefix)){ $displayName = $displayName + " " + $partnerPrefix }
                $displayName = $displayName + " " + $partnerLastname
    
                $displayName = $displayName + " -"
    
                if(-not[String]::IsNullOrEmpty($prefix)){ $displayName = $displayName + " " + $prefix }
                $displayName = $displayName + " " + $lastName
    
                $displayName = $displayName + " " + "($externalID)"
            }
            'P' {
                # Partnername
                $displayName = $firstName
    
                if(-not[String]::IsNullOrEmpty($partnerPrefix)){ $displayName = $displayName + " " + $partnerPrefix }
                $displayName = $displayName + " " + $partnerLastname
    
                $displayName = $displayName + " " + "($externalID)"         
            }
            'C' {
                # # Birthname - Partnername
                $displayName = $firstName
    
                if(-not[String]::IsNullOrEmpty($prefix)){ $displayName = $displayName + " " + $prefix }
                $displayName = $displayName + " " + $lastName
    
                $displayName = $displayName + " -"
    
                if(-not[String]::IsNullOrEmpty($partnerPrefix)){ $displayName = $displayName + " " + $partnerPrefix }
                $displayName = $displayName + " " + $partnerLastname                    
    
                $displayName = $displayName + " " + "($externalID)"
            }
            default {
                # Birthname
                $displayName = $firstName
    
                if(-not[String]::IsNullOrEmpty($prefix)){ $displayName = $displayName + " " + $prefix }
                $displayName = $displayName + " " + $lastName
    
                $displayName = $displayName + " " + "($externalID)"        
            }
        }
        $personObject | Add-Member -Name "ExternalId" -MemberType NoteProperty -Value $externalID;
        $personObject | Add-Member -Name "DisplayName" -MemberType NoteProperty -Value $displayName;

        $contractObject = $person | Select-Object  -Property wns_id, functienr, functienaam, description, deskundigheid, aanvang_dvb_plan, einde_dvb_plan, aanvang_functie_plan, einde_functie_plan, afd_nr, afd_naam, costcenter, costcenter_name, Division, ManagerLoginName, ManagerEmailAddress, dvb_id_actief, dvb_id, con_id, con_id_hfd, werknemersgroep, uren, aanvang_functie, einde_functie, aanvang_adres, einde_adres, aanvang_contract, einde_contract, BIG_nummer, Locatie -Unique;
      
        $managerId = Get-ManagerId $contractObject.ManagerLoginName;
        
        $contractObject | Add-Member -Name "ManagerId" -MemberType NoteProperty -Value $managerId;
        $contractObject | Add-Member -Name "ContractSequence" -MemberType NoteProperty -Value $counter;

        $personObject | Add-Member @{
            Contracts = [System.Collections.ArrayList]@()
        }

        $personObject.Contracts.Add($contractObject) | Out-Null
        $personList.Add($personObject) | Out-Null

        $lastPerson = $person.wns_id;
    }
    else {
        $index = [array]::IndexOf($personList.UniqueID, $($person.UniqueID))

        $contractObject = $person | Select-Object  -Property wns_id, functienr, functienaam, description, deskundigheid, aanvang_dvb_plan, einde_dvb_plan, aanvang_functie_plan, einde_functie_plan, afd_nr, afd_naam, costcenter, costcenter_name, Division, ManagerLoginName, ManagerEmailAddress, dvb_id_actief, dvb_id, con_id, con_id_hfd, werknemersgroep, uren, aanvang_functie, einde_functie, aanvang_adres, einde_adres, aanvang_contract, einde_contract, BIG_nummer, Locatie;

        $managerId = Get-ManagerId $contractObject.ManagerLoginName;
        
        $contractObject | Add-Member -Name "ManagerId" -MemberType NoteProperty -Value $managerId;
        $contractObject | Add-Member -Name "ContractSequence" -MemberType NoteProperty -Value $counter;
        
        $personList[$index].Contracts.Add($contractObject) | Out-Null

        $lastPerson = $person.wns_id;
    }

}

Write-Output $personList | ConvertTo-Json -Depth 10;
