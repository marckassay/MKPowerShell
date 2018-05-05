using module ..\.\TestFunctions.psm1
$MODULE_FOLDER = 'E:\marckassay\MK.PowerShell\MK.PowerShell.4PS'

Describe "Test Update-RootModuleUsingStatements" {
    BeforeAll {
        $__ = [TestFunctions]::DescribeSetup($MODULE_FOLDER, 'TestModuleA')
    }
    
    AfterAll {
        [TestFunctions]::DescribeTeardown(@('MK.PowerShell.4PS', 'MKPowerShellDocObject', 'TestModuleA', 'TestFunctions'))
    }
    
    Context "Recurse src directory for correct function files" {

        It "Should modify empty root module 'using' statments" {
            Update-RootModuleUsingStatements -Path 'TestDrive:\TestModuleA'
            $Results = Get-Content -Path 'TestDrive:\TestModuleA\TestModuleA.psm1'
            $Results.Count | Should -Be 4

            $Assert = $Results[0] 
            $Assert | Should -Be 'using module .\src\C\Get-CFunction.ps1'

            $Assert = $Results[1] 
            $Assert | Should -Be ' using module .\src\C\Set-CFunction.ps1'

            $Assert = $Results[2] 
            $Assert | Should -Be ' using module .\src\Get-AFunction.ps1'

            $Assert = $Results[3] 
            $Assert | Should -Be ' using module .\src\Get-BFunction.ps1'
        }

        It "Should modify root module which declares a function with 'using' statements" {
            Set-Content -Path 'TestDrive:\TestModuleA\TestModuleA.psm1' -Value @"
function Remove-CFunction {
    [CmdletBinding()]
    param (
        
    )
    
}
"@

            Update-RootModuleUsingStatements -Path 'TestDrive:\TestModuleA'
            $Results = Get-Content -Path 'TestDrive:\TestModuleA\TestModuleA.psm1'
            $Results.Count | Should -Be 12

            $Assert = $Results[0] 
            $Assert | Should -Be 'using module .\src\C\Get-CFunction.ps1'

            $Assert = $Results[1] 
            $Assert | Should -Be ' using module .\src\C\Set-CFunction.ps1'

            $Assert = $Results[2] 
            $Assert | Should -Be ' using module .\src\Get-AFunction.ps1'

            $Assert = $Results[3] 
            $Assert | Should -Be ' using module .\src\Get-BFunction.ps1'

            $Assert = $Results[4] 
            $Assert | Should -Be ''
        }

        It "Should modify root module which declares a function and contains a 'using' statement with more statements" {
            Set-Content -Path 'TestDrive:\TestModuleA\TestModuleA.psm1' -Value @"
using module .\src\C\New-CFunction.ps1'
function Remove-CFunction {
    [CmdletBinding()]
    param (
        
    )
    
}
"@ 

            Update-RootModuleUsingStatements -Path 'TestDrive:\TestModuleA'
            $Results = Get-Content -Path 'TestDrive:\TestModuleA\TestModuleA.psm1'
            $Results.Count | Should -Be 12

            $Assert = $Results[0] 
            $Assert | Should -Be 'using module .\src\C\Get-CFunction.ps1'

            $Assert = $Results[1] 
            $Assert | Should -Be ' using module .\src\C\Set-CFunction.ps1'

            $Assert = $Results[2] 
            $Assert | Should -Be ' using module .\src\Get-AFunction.ps1'

            $Assert = $Results[3] 
            $Assert | Should -Be ' using module .\src\Get-BFunction.ps1'

            $Assert = $Results[4] 
            $Assert | Should -Be ''
        }
    }
}