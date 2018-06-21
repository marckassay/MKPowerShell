# NoExport: Get-ManifestKey
function Get-ManifestKey {
    [CmdletBinding(PositionalBinding = $True, 
        DefaultParameterSetName = "ByPath")]
    Param
    (
        [Parameter(Mandatory = $False,
            Position = 0,
            ValueFromPipeline = $False, 
            ParameterSetName = "ByPath")]
        [string]$Path = '.',

        [Parameter(Mandatory = $True)]
        [ValidateSet("AliasesToExport", "FunctionsToExport", "RootModule", "TypesToProcess", "CmdletsToExport", "PrivateData", "FileList", "Author", "ModuleVersion", "CompanyName", "FormatsToProcess", "GUID", "Copyright")]
        [String]$Key
    )
    
    DynamicParam {
        return GetModuleNameSet -Position 0 -Mandatory 
    }

    begin {
        $Name = $PSBoundParameters['Name']
    }

    end {
        if ($PSBoundParameters.Name) {
            $ModInfo = Get-MKModuleInfo -Name $Name
        }
        else {
            $ModInfo = Get-MKModuleInfo -Path $Path
        }
    
        try {
            $Results = (Import-PowerShellDataFile -Path $ModInfo.ManifestFilePath)[$Key]
        }
        catch {
        
        }

        $Results
    }
}