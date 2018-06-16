# NoExport: Invoke-TestSuiteRunner
function Invoke-TestSuiteRunner {
    [CmdletBinding(PositionalBinding = $True, 
        DefaultParameterSetName = "ByPath")]
    Param
    (
        [Parameter(Mandatory = $False,
            Position = 0,
            ValueFromPipeline = $False, 
            ParameterSetName = "ByPath")]
        [string]$Path = '.'
    )

    DynamicParam {
        return GetModuleNameSet -Position 0 -Mandatory 
    }
    
    begin {
        $Name = $PSBoundParameters['Name']

        if ($Name) {
            $ModInfo = Get-MKModuleInfo -Name $Name
        }
        else {
            $ModInfo = Get-MKModuleInfo -Path $Path
        }

        Push-Location -StackName 'PriorTestLocation'
        
        # Test-ModuleManifest $ModInfo.ManifestPath | Remove-Module
    }

    process {
        Invoke-Command {Invoke-Pester -Script "$($ModInfo.Path)\test"}
    }

    end {
        Pop-Location -StackName 'PriorTestLocation'

        # Import-Module -Name ($ModInfo.ModuleBase)
    }
}