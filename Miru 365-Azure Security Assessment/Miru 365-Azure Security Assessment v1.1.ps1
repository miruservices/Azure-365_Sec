<# 
. Name:
        Miru 365-Azure Security Assessment v1.1
    

. Descr
    

. Version:
    

. Features: 
    

. Release notes:
    

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



function GetAzRoleAssignmentDetails_User {
    $AzRoleAssignmentDisplayName = $currentItemName.DisplayName
    Add-content $global:ResultFile " DisplayName: $AzRoleAssignmentDisplayName"
    $AzRoleAssignmentSignInName = $currentItemName.SignInName
    Add-content $global:ResultFile " SignInName: $AzRoleAssignmentSignInName"
    $AzRoleAssignmentRoleDefinitionName = $currentItemName.RoleDefinitionName
    Add-content $global:ResultFile " RoleDefinitionName: $AzRoleAssignmentRoleDefinitionName"
    $AzRoleAssignmentScope = $currentItemName.Scope
    Add-content $global:ResultFile " Scope: $AzRoleAssignmentScope"
    #Write-Host "ObjectType:" $currentItemName.ObjectType
    Add-content $global:ResultFile "`n"
}

function GetAzRoleAssignmentDetails_ServicePrincipal {

    $AzRoleAssignmentDisplayName = $currentItemName.DisplayName
    Add-content $global:ResultFile " DisplayName: $AzRoleAssignmentDisplayName"
    Add-content $global:ResultFile " SignInName: $AzRoleAssignmentSignInName"
    $AzRoleAssignmentRoleDefinitionName = $currentItemName.RoleDefinitionName
    Add-content $global:ResultFile " RoleDefinitionName: $AzRoleAssignmentRoleDefinitionName"
    $AzRoleAssignmentScope = $currentItemName.Scope
    Add-content $global:ResultFile " Scope: $AzRoleAssignmentScope"
    #Write-Host "ObjectType:" $currentItemName.ObjectType
    Add-content $global:ResultFile "`n"
}

function ResetCounter {
    [int32]$global:Counter = $null
    
}

function DisplayCounter {
    AddLineToResultFile
    Add-content $global:ResultFile " Total: $global:Counter"
    AddBlankRowToResultFile

}


function GetAzRoleAssignment {
   

$global:GetAzRoleAssignment = @()
ResetCounter

$global:GetAzRoleAssignment = Get-AzRoleAssignment -Scope $global:AzSubscription_id

AddLineToResultFile
$global:GetAzRoleAssignmentLength = $global:GetAzRoleAssignment.Length
Add-content $global:ResultFile " Total AzRoleAssignments: $global:GetAzRoleAssignmentLength"

AddLineToResultFile
Add-content $global:ResultFile " SCOPE: At Subscription Level"
Add-content $global:ResultFile " TYPE:  User"
AddLineToResultFile 

foreach ($currentItemName in $global:GetAzRoleAssignment) {

    if ($currentItemName.Scope -eq $global:AzSubscription_id -AND $currentItemName.ObjectType -eq "User") {
        $global:Counter ++
        GetAzRoleAssignmentDetails_User
    }
    
}

DisplayCounter
ResetCounter

AddLineToResultFile
Add-content $global:ResultFile " SCOPE: At Subscription Level"
Add-content $global:ResultFile " TYPE:  Not User"
AddLineToResultFile 

foreach ($currentItemName in $global:GetAzRoleAssignment) {

    if ($currentItemName.Scope -eq $global:AzSubscription_id -AND $currentItemName.ObjectType -ne "User") {
        $global:Counter ++
        GetAzRoleAssignmentDetails_ServicePrincipal
    }
    
}

DisplayCounter
ResetCounter

AddLineToResultFile
Add-content $global:ResultFile " SCOPE: Not Inherited from subscription"
Add-content $global:ResultFile " TYPE:  User"
AddLineToResultFile

foreach ($currentItemName in $global:GetAzRoleAssignment) {

    if ($currentItemName.Scope -ne $global:AzSubscription_id -AND $currentItemName.ObjectType -eq "User") {
        $global:Counter ++
        GetAzRoleAssignmentDetails_User
    }
    
}

DisplayCounter
ResetCounter

AddLineToResultFile
Add-content $global:ResultFile " SCOPE: Not Inherited from subscription"
Add-content $global:ResultFile " TYPE:  Not User`n"
AddLineToResultFile 

foreach ($currentItemName in $global:GetAzRoleAssignment) {

    if ($currentItemName.Scope -ne $global:AzSubscription_id -AND $currentItemName.ObjectType -ne "User") {
        $global:Counter ++
        GetAzRoleAssignmentDetails_ServicePrincipal
    }
    
}

DisplayCounter
ResetCounter
    
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

function Prerequests {
    
    Write-Host "`n"
    Write-Host " DISCLAIMER: We strongly recommend that you only use an account that has read only rights (Global Reader role)."
    Write-Host " REQUIREMENTS: Global reader role in tenant and read at subscription level in Azure."
    Write-Host " INFO: All assesment results will be saved in separate files in session folder at this running directory."
    Write-Host " INFO: A Readmefile and errorfile will be created as well."
    Write-Host "`n"
    $global:Disclaimer_input = Read-Host -Prompt 'Type YES to confirm'

    if ($global:Disclaimer_input -ne "YES") {
        Write-host " + $(Get-TimeStamp) Not confirmed by YES. Now terminating..."
        exit 1
    }

    $global:CompanyName_input = Read-Host -Prompt 'Type Company Name'
    $global:AzSubscription_id_input = Read-Host -Prompt 'Input your AzSubscription_id'

    if (!$global:AzSubscription_id_input) {
        Write-host " + $(Get-TimeStamp) AzSubscription_id blank. Now terminating..."
        exit 1
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

    Write-host " + $(Get-TimeStamp) Connect-AzAccount..."
    Connect-AzAccount



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


    $global:AzSubscription_id = "/subscriptions/$global:AzSubscription_id_input"


    $global:GraphPermissionsIDMappingArray = @()
    $global:GraphPermissionsIDMappingArray = Import-Csv -Path .\GraphPermissionsIDMapping.csv -Delimiter ";"

    $global:AssessmentSessionFolderName = "Miru 365-Azure Security Assessment__" + $global:CompanyName_input + "__" + $global:SessionID

    If (!(test-path $global:AssessmentSessionFolderName))
    { New-Item -ItemType Directory -Force -Path $global:AssessmentSessionFolderName | Out-Null }

    $global:ReadmeFile = $global:AssessmentSessionFolderName+"\Readme.txt"
    New-Item $global:ReadmeFile | Out-Null
    Add-content $global:ReadmeFile "Company Name: $global:CompanyName_input"
    Add-content $global:ReadmeFile "Azure Subscription ID: $global:AzSubscription_id_input"
    Add-content $global:ReadmeFile "`n"
    Add-content $global:ReadmeFile "This assessment needs to be supplemented with monitor metric results from Miru for Microsoft 365 service and other technical controls in Miru Companion."
    
}

function AddLineToResultFile {

    Add-content $global:ResultFile "________________________________________________________________"

}

function AddBlankRowToResultFile {

    Add-content $global:ResultFile "`n"

}

function GetAzureADAdminRoleMembers {

    ResetCounter
    $global:GetAzureADDirectoryRoleObjectIdArray = @()
    $global:GetAzureADDirectoryRole = Get-AzureADDirectoryRole

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
            Add-content $global:ResultFile "DisplayName: $GetAzureADDirectoryRoleDisplayName | ObjectId: $AzureADDirectoryRoleObjectId "
    
            $GetAzureADDirectoryRoleMemberObjectId = $GetAzureADDirectoryRoleMemberArray.ObjectId
            Add-content $global:ResultFile "MemberObjectId: $GetAzureADDirectoryRoleMemberObjectId"

            AddBlankRowToResultFile

            $GetAzureADDirectoryRoleMemberDisplayName = $GetAzureADDirectoryRoleMemberArray.DisplayName
            Add-content $global:ResultFile "MemberArray_DisplayName: $GetAzureADDirectoryRoleMemberDisplayName"

            $GetAzureADDirectoryRoleMemberUserPrincipalName = $GetAzureADDirectoryRoleMemberArray.UserPrincipalName
            Add-content $global:ResultFile "MemberArray_UserPrincipalName: $GetAzureADDirectoryRoleMemberUserPrincipalName"

            AddLineToResultFile
                
        }

    }

}

function GetAzResource {
    
    ResetCounter

    #Get-AzResource | Sort-Object -Property Name | Format-Table -GroupBy ResourceType
    Get-AzResource | Export-Csv $global:ResultFile

}

function GetAzPublicIpAddress {

    ResetCounter
    # Get-AzPublicIpAddress | Format-Table
    # Get-AzPublicIpAddress | Format-List -Property *
    Get-AzPublicIpAddress | Export-Csv $global:ResultFile

}


function GetAzVM {

    ResetCounter
    Get-AzVM | Export-Csv $global:ResultFile
    
}

function GetAzNetworkSecurityGroup {

    ResetCounter
    Get-AzNetworkSecurityGroup | Export-Csv $global:ResultFile
}
 

Write-host " + $(Get-TimeStamp) Miru 365-Azure Security Assessment started"
Write-host " + $(Get-TimeStamp) Session ID: $global:SessionID"

Prerequests

Write-host " + $(Get-TimeStamp) Starting GetAzRoleAssignment function..." 
$global:ResultFile = $global:AssessmentSessionFolderName+"\AzRoleAssignment.txt"
New-Item $global:ResultFile | Out-Null
GetAzRoleAssignment

Write-host " + $(Get-TimeStamp) Starting GetAzureADApplicationDetailed function..." 
$global:ResultFile = $global:AssessmentSessionFolderName+"\AzureADApplications.txt"
New-Item $global:ResultFile | Out-Null
GetAzureADApplicationDetailed

Write-host " + $(Get-TimeStamp) Starting GetAzureADAdminRoleMembers function..." 
$global:ResultFile = $global:AssessmentSessionFolderName+"\GetAzureADAdminRoleMembers.txt"
New-Item $global:ResultFile | Out-Null
GetAzureADAdminRoleMembers

Write-host " + $(Get-TimeStamp) Starting GetAzResource function..." 
$global:ResultFile = $global:AssessmentSessionFolderName+"\GetAzResource.csv"
New-Item $global:ResultFile | Out-Null
GetAzResource


Write-host " + $(Get-TimeStamp) Starting GetAzPublicIpAddress function..." 
$global:ResultFile = $global:AssessmentSessionFolderName+"\GetAzPublicIpAddress.csv"
New-Item $global:ResultFile | Out-Null
GetAzPublicIpAddress

Write-host " + $(Get-TimeStamp) Starting GetAzVM function..." 
$global:ResultFile = $global:AssessmentSessionFolderName+"\GetAzVM.csv"
New-Item $global:ResultFile | Out-Null
GetAzVM

Write-host " + $(Get-TimeStamp) Starting GetAzNetworkSecurityGroup function..." 
$global:ResultFile = $global:AssessmentSessionFolderName+"\GetAzNetworkSecurityGroup.csv"
New-Item $global:ResultFile | Out-Null
GetAzNetworkSecurityGroup


Write-host " + $(Get-TimeStamp) Disconnect-AzAccount..."
Disconnect-AzAccount

Write-host " + $(Get-TimeStamp) Disconnect-AzureAD..."
Disconnect-AzureAD

Write-host " + $(Get-TimeStamp) Component ended"
 
if ($Error) {
    $global:ResultFile = $global:AssessmentSessionFolderName+"\ScriptError.txt"
    New-Item $global:ResultFile | Out-Null
    Add-content $global:ResultFile $Error
}


