using module ..\..\.\TestRunnerSupportModule.psm1

Describe "Test Update-SemVer" {
    BeforeAll {
        $TestSupportModule = [TestRunnerSupportModule]::new('MockModuleB')
    }
    
    AfterAll {
        $TestSupportModule.Teardown()
    }

    Context "Calling Update-SemVer with Path to module directory" {

        It "Should start off with the expected version number" {
            $CurrentVersion = $(Import-PowerShellDataFile -Path ($TestSupportModule.MockManifestPath))['ModuleVersion']
            $CurrentVersion | Should -Be '0.0.1'
        }

        It "Should bump Major" {
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -BumpMajor
            $Results | Should -Be '1.0.1'
        }

        It "Should bump Patch" {
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -BumpPatch
            $Results | Should -Be '1.0.2'
        }

        It "Should bump Minor and Patch" {
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -BumpPatch -BumpMinor
            $Results | Should -Be '1.1.3'
        }

        It "Should change version to explict value" {
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -Value '2.0.0'
            $Results | Should -Be '2.0.0'
        }

        It "Should change version using positional parameter values for the trio" {
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) 1 2 3
            $Results | Should -Be '1.2.3'
        }

        It "Should change version using parameter values for the trio" {
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -Major 1 -Minor 0 -Patch 0
            $Results | Should -Be '1.0.0'
        }
    }

    Context "Calling Update-SemVer with -AutoUpdate" {
        Push-Location
        Set-Location $TestSupportModule.MockDirectoryPath
            
        Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -Value '3.0.0'

        It "Should change version to Git branch name - 3.0.1" {

            Invoke-Expression -Command 'git checkout -b 3.0.1'
            
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -AutoUpdate
            $Results | Should -Be '3.0.1'
        }

        It "Should change version to Git branch name - 3.1.1" {
 
            Invoke-Expression -Command 'git checkout -b 3.1.1'
            
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -AutoUpdate
            $Results | Should -Be '3.1.1'
        }

        It "Should change version to Git branch name - 4.0.0" {
 
            Invoke-Expression -Command 'git checkout -b 4.0.0'
            
            $Results = Update-SemVer -Path ($TestSupportModule.MockDirectoryPath) -AutoUpdate
            $Results | Should -Be '4.0.0'
        }

        Pop-Location
    }
}
