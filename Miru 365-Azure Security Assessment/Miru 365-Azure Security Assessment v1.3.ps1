<# 
. Name:
        Miru 365-Azure Security Assessment v1.3
    

. Descr
    

. Version:
    

. Features: 
    

. Release notes:
    v1.3:
        - Added condition: If Azure subscription is empty, script will continue with Azure assessment excluded.
    v1.2:
        - Rewrite to export result into Excel report

    v1.1:
        - 
    v1.0:
        - GA
    

. Notes



. Ref links:


    
 #>

$error.clear()
$ErrorActionPreference = 'SilentlyContinue'
$global:var_Now = (Get-Date -format "yyyy-MM-dd HH:mm")
$global:SessionID = (get-date -format yyyy-MM-ddTHH-mm-ss-ff) 
  
 
$global:AlertMessage = ''
[int32]$global:AlertCounter = $null

$global:ResultFile = $null

$global:AzSubscription_id = $null
$global:AzSubscription_id_input = $null
 
 Write-Host "
 
  _____ ______       ___      ________      ___  ___         
 |\   _ \  _   \    |\  \    |\   __  \    |\  \|\  \        
 \ \  \\\__\ \  \   \ \  \   \ \  \|\  \   \ \  \\\  \       
  \ \  \\|__| \  \   \ \  \   \ \   _  _\   \ \  \\\  \      
   \ \  \    \ \  \   \ \  \   \ \  \\  \|   \ \  \\\  \     
    \ \__\    \ \__\   \ \__\   \ \__\\ _\    \ \_______\    
     \|__|     \|__|    \|__|    \|__|\|__|    \|_______|    
                                                             
                                                             
                                                             
 "
 
 
function Get-TimeStamp {
    
    return "[{0:yyyy/MM/dd} {0:HH:mm:ss}]" -f (Get-Date)
     
}



function GetAzRoleAssignmentDetails {

    $AzRoleAssignmentDisplayName = $currentItemName.DisplayName
    $AzRoleAssignmentSignInName = $currentItemName.SignInName
    $AzRoleAssignmentRoleDefinitionName = $currentItemName.RoleDefinitionName
    $AzRoleAssignmentScope = $currentItemName.Scope
    $AzRoleAssignmentObjectType = $currentItemName.ObjectType
    
    Add-content $global:ResultFile "$AzRoleAssignmentDisplayName;$AzRoleAssignmentSignInName;$AzRoleAssignmentRoleDefinitionName;$AzRoleAssignmentScope;$AzRoleAssignmentObjectType;"

}

function ResetCounter {

    [int32]$global:Counter = $null
    
}

function DisplayCounter {
    AddLineToResultFile
    Add-content $global:ResultFile " Total: $global:Counter"
    AddBlankRowToResultFile

}


function AddLineToResultFile {

    Add-content $global:ResultFile "________________________________________________________________"

}

function AddBlankRowToResultFile {

    Add-content $global:ResultFile "`n"

}

function GetAzRoleAssignment {
   

$global:GetAzRoleAssignment = @()
ResetCounter

$global:GetAzRoleAssignment = Get-AzRoleAssignment -Scope $global:AzSubscription_id


$global:GetAzRoleAssignmentLength = $global:GetAzRoleAssignment.Length
#Add-content $global:ResultFile " Total AzRoleAssignments: $global:GetAzRoleAssignmentLength"

Add-content $global:ResultFile "DisplayName;SignInName;RoleDefinitionName;Scope;ObjectType"

foreach ($currentItemName in $global:GetAzRoleAssignment) {

    $global:Counter ++
    GetAzRoleAssignmentDetails
        
}
    
}

function TranslateGraphPermissionsID {

    foreach ($currentItemName in $global:GraphPermissionsIDMappingArray) {
        $GraphPermissionsIDMappingArrayID = $null
        $GraphPermissionsIDMappingArrayID = $currentItemName.Id

        $GraphPermissionsIDMappingArrayPermissionName = $null
        $GraphPermissionsIDMappingArrayPermissionName = $currentItemName.PermissionName
        
        if ($CurrentID -eq $GraphPermissionsIDMappingArrayID) {
            Add-content $global:ResultFile "PermissionName: $GraphPermissionsIDMappingArrayPermissionName"
        }
    }
   
}

function GetAzureADApplicationDetailed {
 
        #Get-AzureADServicePrincipal -all $true | Select-Object DisplayName, AppId  | Format-Table
    
        $AzureADServicePrincipal = Get-AzureADServicePrincipal -all $true | Where-Object {$_.Tags -ne $Null}
        ResetCounter
        
        foreach ($ServicePrincipal in $AzureADServicePrincipal) {
            $GetAzADAppPermission = $null
            $global:Counter ++
            AddLineToResultFile
            $AppName = $ServicePrincipal.DisplayName
            Add-content $global:ResultFile "AppName: $AppName"
            $AppID = $ServicePrincipal.AppId
            Add-content $global:ResultFile "AppID: $AppID"
            $ObjectID = $ServicePrincipal.ObjectID
            Add-content $global:ResultFile "ObjectID: $ObjectID"
            $PublisherName = $ServicePrincipal.PublisherName
            Add-content $global:ResultFile "PublisherName: $PublisherName"
            $AccountEnabled = $ServicePrincipal.AccountEnabled
            Add-content $global:ResultFile "AccountEnabled: $AccountEnabled"
            $AppOwnerTenantId = $ServicePrincipal.AppOwnerTenantId
            Add-content $global:ResultFile "AppOwnerTenantId: $AppOwnerTenantId"
            $AppRoleAssignmentRequired = $ServicePrincipal.AppRoleAssignmentRequired
            Add-content $global:ResultFile "AppRoleAssignmentRequired: $AppRoleAssignmentRequired"
            $ServicePrincipalType = $ServicePrincipal.ServicePrincipalType
            Add-content $global:ResultFile "ServicePrincipalType: $ServicePrincipalType"
            $Tags = $ServicePrincipal.Tags
            Add-content $global:ResultFile "Tags: $Tags"
            $applicationType = $ServicePrincipal.applicationType
            Add-content $global:ResultFile "ApplicationType: $applicationType"
            $AppRoleAssignment = Get-AzureADServiceAppRoleAssignment -ObjectId $ObjectID
            Add-content $global:ResultFile "AppRoleAssignment: $AppRoleAssignment"
            $AppRoleAssignedTo = Get-AzureADServiceAppRoleAssignedTo -ObjectId $ObjectID
            Add-content $global:ResultFile "AppRoleAssignedTo: $AppRoleAssignedTo"
            $AppOauth2Permissions = $ServicePrincipal.Oauth2Permissions
            Add-content $global:ResultFile "AppOauth2Permissions: $AppOauth2Permissions"
        
            $GetAzADAppPermission = Get-AzADAppPermission -ApplicationId $AppID -erroraction 'silentlycontinue'
                    
                foreach ($currentItemName in $GetAzADAppPermission) {
                    [string]$CurrentID = $null
                    $CurrentID = $currentItemName.Id
                    TranslateGraphPermissionsID
                    
                    }
                
                }
            
            DisplayCounter
}


function GetAzureADApplication {
 
    #Get-AzureADServicePrincipal -all $true | Select-Object DisplayName, AppId  | Format-Table

    $AzureADServicePrincipal = Get-AzureADServicePrincipal -all $true | Where-Object {$_.Tags -ne $Null}
    ResetCounter

    Add-content $global:ResultFile "DisplayName;AppId;ObjectID;PublisherName;AccountEnabled;AppOwnerTenantId;AppRoleAssignmentRequired;ServicePrincipalType;Tags;ApplicationType"

    foreach ($ServicePrincipal in $AzureADServicePrincipal) {
        $GetAzADAppPermission = $null
        $global:Counter ++
        $DisplayName = $ServicePrincipal.DisplayName
        $AppID = $ServicePrincipal.AppId
        $ObjectID = $ServicePrincipal.ObjectID
        $PublisherName = $ServicePrincipal.PublisherName
        $AccountEnabled = $ServicePrincipal.AccountEnabled
        $AppOwnerTenantId = $ServicePrincipal.AppOwnerTenantId
        $AppRoleAssignmentRequired = $ServicePrincipal.AppRoleAssignmentRequired
        $ServicePrincipalType = $ServicePrincipal.ServicePrincipalType
        $Tags = $ServicePrincipal.Tags
        $ApplicationType = $ServicePrincipal.ApplicationType

        Add-content $global:ResultFile "$DisplayName;$AppID;$ObjectID;$PublisherName;$AccountEnabled;$AppOwnerTenantId;$AppRoleAssignmentRequired;$ServicePrincipalType;$Tags;$ApplicationType"
    
    }

}

function Prerequests {
    
    [console]::Foregroundcolor = "Red"
    Write-Host "`n"
    Write-Host " ! ATTENTION !"
    Write-Host " We strongly recommend that you only use an account that has read only rights (Global Reader role). Primarily to minimize impact if credentials are stolen and to apply just enough rights principle"

    [Console]::ResetColor()
    Write-Host "`n"
    Write-Host " REQUIREMENTS:"
    Write-Host " Global reader role in tenant and read at subscription level in Azure."
    Write-Host "`n"
    Write-Host " INFO:"
    Write-Host " All assesment results will be saved in a report Excel file. All raw data will be saved in separate files in raw folder in session folder at this running directory."
    Write-Host " A Readmefile and errorfile will be created as well."
    Write-Host "`n"
    $global:Disclaimer_input = Read-Host -Prompt 'Type YES to confirm'

    if ($global:Disclaimer_input -ne "YES") {
        Write-host " + $(Get-TimeStamp) Not confirmed by YES. Now terminating..."
        exit 1
    }

    $global:CompanyName_input = Read-Host -Prompt 'Type Company Name'
    $global:AzSubscription_id_input = Read-Host -Prompt 'Input your AzSubscription_id'

    if (!$global:AzSubscription_id_input) {
        Write-host " - $(Get-TimeStamp) ALERT! AzSubscription_id blank. Azure assessment will be excluded."
    }

    Write-host " + $(Get-TimeStamp) Prerequest check: ImportExcel Resources module"
    $global:CheckImportExcelModule = Get-Module -ListAvailable -Name ImportExcel

    if ($global:CheckImportExcelModule) {
        Write-host " + $(Get-TimeStamp) Module exist."
    } 

    if (!$global:CheckImportExcelModule) {
        Write-host " + $(Get-TimeStamp) Module does not exist. Now installing..."
        Install-Module ImportExcel -Force
    } 
    
    Write-host " + $(Get-TimeStamp) Prerequest check: Az.Resources module"
    $global:CheckAzResourcesModule = Get-Module -ListAvailable -Name Az.Resources

    if ($global:CheckAzResourcesModule) {
        Write-host " + $(Get-TimeStamp) Module exist."
    } 

    if (!$global:CheckAzResourcesModule) {
        Write-host " + $(Get-TimeStamp) Module does not exist. Now installing..."
        Install-Module Az -Force
    } 





    Write-host " + $(Get-TimeStamp) Prerequest check: AzureAD module"
    $global:CheckAzureADModule = Get-Module -ListAvailable -Name AzureAD
    
    if ($global:CheckAzureADModule) {
        Write-host " + $(Get-TimeStamp) Module exist."
    } 

    if (!$global:CheckAzureADModule) {
        Write-host " + $(Get-TimeStamp) Module does not exist. Now installing..."
        Install-Module AzureAD -Foce
    } 

    Write-host " + $(Get-TimeStamp) Connect-AzureAD..."
    Connect-AzureAD

    Write-host " + $(Get-TimeStamp) Connect-AzAccount..."
    Connect-AzAccount

    $global:AzSubscription_id = "/subscriptions/$global:AzSubscription_id_input"


    $global:GraphPermissionsIDMappingArray = @()
    $global:GraphPermissionsIDMappingArray = Import-Csv -Path .\GraphPermissionsIDMapping.csv -Delimiter ";"

    $global:CurrentDirectory = get-location
    $global:CurrentDirectoryPath = $global:CurrentDirectory.Path

    $global:AssessmentSessionFolderPath = $global:CurrentDirectoryPath + "\Miru 365-Azure Security Assessment__" + $global:CompanyName_input + "__" + $global:SessionID
    $global:AssessmentRawSessionFolderPath = $global:AssessmentSessionFolderPath + "\Raw"
    $global:AssessmentExcelReportPath = $global:AssessmentSessionFolderPath + "\Miru 365-Azure Security Assessment Report__" + $global:CompanyName_input + "__" + $global:SessionID + ".xlsx"
    
    If (!(test-path $global:AssessmentSessionFolderPath))
    { New-Item -ItemType Directory -Force -Path $global:AssessmentSessionFolderPath | Out-Null }

    If (!(test-path $global:AssessmentRawSessionFolderPath))
    { New-Item -ItemType Directory -Force -Path $global:AssessmentRawSessionFolderPath | Out-Null }
   
}

function GetAzureADAdminRoleMembers {

    ResetCounter
    $global:GetAzureADDirectoryRoleObjectIdArray = @()
    $global:GetAzureADDirectoryRole = Get-AzureADDirectoryRole

    Add-content $global:ResultFile "DisplayName;MemberArray_UserPrincipalName;MemberArray_DisplayName;ObjectId;MemberObjectId"


    foreach ($currentItemName in $global:GetAzureADDirectoryRole) {
        $global:GetAzureADDirectoryRoleObjectIdArray += $currentItemName.ObjectId
        #Write-host " + $(Get-TimeStamp) ObjectId:" $currentItemName.ObjectId
        #Write-host " + $(Get-TimeStamp) DisplayName:" $currentItemName.DisplayName
        
    }

    foreach ($AzureADDirectoryRoleObjectId in $global:GetAzureADDirectoryRoleObjectIdArray) {
        $GetAzureADDirectoryRoleMemberArray = @()
        $GetAzureADDirectoryRoleDisplayName = $null
        $GetAzureADDirectoryRoleDisplayName = Get-AzureADDirectoryRole -ObjectId $AzureADDirectoryRoleObjectId | Select-Object -ExpandProperty DisplayName

        $GetAzureADDirectoryRoleMemberArray = Get-AzureADDirectoryRoleMember -ObjectId $AzureADDirectoryRoleObjectId
        
        if ($GetAzureADDirectoryRoleMemberArray) {
            $global:Counter ++

            $GetAzureADDirectoryRoleMemberObjectId = $GetAzureADDirectoryRoleMemberArray.ObjectId
            $GetAzureADDirectoryRoleMemberDisplayName = $GetAzureADDirectoryRoleMemberArray.DisplayName
            $GetAzureADDirectoryRoleMemberUserPrincipalName = $GetAzureADDirectoryRoleMemberArray.UserPrincipalName
            Add-content $global:ResultFile "$GetAzureADDirectoryRoleDisplayName;$GetAzureADDirectoryRoleMemberUserPrincipalName;$GetAzureADDirectoryRoleMemberDisplayName;$AzureADDirectoryRoleObjectId;$GetAzureADDirectoryRoleMemberObjectId"
    
        }

    }

}

function CreateExcelFile {

        # Create a new Excel workbook with one empty sheet
        $global:ExcelObject = New-Object -ComObject excel.application 
        $global:Workbook = $global:ExcelObject.Workbooks.Add(1)
        $worksheet = $global:Workbook.worksheets.Item(1)
        $global:Workbook.WorkSheets.item(1).Name = "Readme"

        $worksheet.Cells.Item(1,1) = "Company Name:"
        $worksheet.Cells.Item(1,2) = "$global:CompanyName_input"
        $worksheet.Cells.Item(2,1) = "Azure Subscription ID:"
        $worksheet.Cells.Item(2,2) = "$global:AzSubscription_id_input"
        $worksheet.Cells.Item(4,1) = "This assessment needs to be supplemented with monitor metric results from Miru for Microsoft 365 service and other technical controls in Miru Companion."
    
        # Save & close the Workbook as XLSX.
        $global:Workbook.SaveAs("$global:AssessmentExcelReportPath",51)
    
        $global:ExcelObject.Quit()
        
        #$null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($global:LastSheet)
        #$null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($global:NewSheet)
        $null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($global:Workbook)
        $null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($global:ExcelObject)
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
  
}


function GetAzResource {
    
    ResetCounter

    #Get-AzResource | Sort-Object -Property Name | Format-Table -GroupBy ResourceType
    Get-AzResource | Export-Csv $global:ResultFile -Delimiter ';'

}

function GetAzPublicIpAddress {

    ResetCounter
    # Get-AzPublicIpAddress | Format-Table
    # Get-AzPublicIpAddress | Format-List -Property *
    Get-AzPublicIpAddress | Export-Csv $global:ResultFile -Delimiter ';'

}


function GetAzVM {

    ResetCounter
    Get-AzVM | Export-Csv $global:ResultFile -Delimiter ';'
    
}

function GetAzNetworkSecurityGroup {

    ResetCounter
    Get-AzNetworkSecurityGroup | Export-Csv $global:ResultFile -Delimiter ';'

}

function RunExcelFunction {

    Write-host " + $(Get-TimeStamp) Starting $global:FunctionName function..."
    $global:ResultFile = $global:AssessmentRawSessionFolderPath+"\$global:FunctionName.csv"
    New-Item $global:ResultFile | Out-Null
    &$global:FunctionName

    Import-Csv -Path "$global:ResultFile" -Delimiter ";" | Export-Excel -Path "$global:AssessmentExcelReportPath" -WorkSheetname "$global:FunctionName"
    
}

function RunTXTFunction {

    Write-host " + $(Get-TimeStamp) Starting $global:FunctionName function..."
    $global:ResultFile = $global:AssessmentSessionFolderPath+"\$global:FunctionName.txt"
    New-Item $global:ResultFile | Out-Null
    &$global:FunctionName
   
}
 

Write-host " + $(Get-TimeStamp) Miru 365-Azure Security Assessment started"
Write-host " + $(Get-TimeStamp) Session ID: $global:SessionID"

Prerequests

CreateExcelFile



$global:FunctionName = "GetAzureADApplication"
RunExcelFunction

$global:FunctionName = "GetAzureADApplicationDetailed"
RunTXTFunction

$global:FunctionName = "GetAzureADAdminRoleMembers"
RunExcelFunction

if ($global:AzSubscription_id_input) {

    $global:FunctionName = "GetAzRoleAssignment"
    RunExcelFunction
    
    $global:FunctionName = "GetAzResource"
    RunExcelFunction

    $global:FunctionName = "GetAzPublicIpAddress"
    RunExcelFunction

    $global:FunctionName = "GetAzVM"
    RunExcelFunction

    $global:FunctionName = "GetAzNetworkSecurityGroup"
    RunExcelFunction



}

Write-host " + $(Get-TimeStamp) Disconnect-AzAccount..."
Disconnect-AzAccount

Write-host " + $(Get-TimeStamp) Disconnect-AzureAD..."
Disconnect-AzureAD

Write-host " + $(Get-TimeStamp) Component ended"
 
if ($Error) {
    $global:ResultFile = $global:AssessmentSessionFolderPath+"\ScriptError.txt"
    New-Item $global:ResultFile | Out-Null
    Add-content $global:ResultFile $Error
}


