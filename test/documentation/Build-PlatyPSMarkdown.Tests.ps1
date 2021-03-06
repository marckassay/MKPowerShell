using module ..\.\TestRunnerSupportModule.psm1

$script:Files
$script:FileNames

Describe "Test Build-PlatyPSMarkdown" {

    BeforeAll {
        $TestSupportModule = [TestRunnerSupportModule]::new('MockModuleB')
        
        # this test file needs the .git repo but not the docs folder
        Remove-Item -Path "$($TestSupportModule.MockDirectoryPath)\docs" -Recurse

        $script:Files = "Get-AFunction.md", "Get-BFunction.md", "Get-CFunction.md", "Set-CFunction.md" | `
            Sort-Object
    }
    
    AfterAll {
        $TestSupportModule.Teardown()
    }

    Context "As a non-piped call, with a given Path value to create files and then to update files 
    with a second call." {

        It "Should generate correct number of files." {
            # NOTE: if this functions re-imports, it will import into a different scope or session.  
            # Although it will still pass, it will write warnings and errors
            Build-PlatyPSMarkdown -Path ($TestSupportModule.MockDirectoryPath) -NoReImportModule

            $script:FileNames = Get-ChildItem "$($TestSupportModule.MockDirectoryPath)\docs" -Recurse | `
                ForEach-Object {$_.Name} | `
                Sort-Object
            
            $script:FileNames.Count | Should -Be 4
        }

        It "Should generate exact filenames." {
            $FileNames | Should -BeExactly $script:Files
        }

        It "Should *create* Get-AFunction.md file at line number <Index> with: {<Expected>}" -TestCases @(
            @{ Index = 0; Expected = "---" },
            @{ Index = 1; Expected = "external help file: MockModuleB-help.xml" },
            @{ Index = 2; Expected = "Module Name: MockModuleB" },
            @{ Index = 3; Expected = "online version: https://github.com/marckassay/MockModuleB/blob/master/docs/Get-AFunction.md"},
            @{ Index = 4; Expected = "schema: 2.0.0" }
            @{ Index = 5; Expected = "---" }
            @{ Index = 6; Expected = "" }
            @{ Index = 7; Expected = "# Get-AFunction" }
            @{ Index = 8; Expected = "" }
            @{ Index = 9; Expected = "## SYNOPSIS" }
            @{ Index = 10; Expected = "{{Fill in the Synopsis}}" }
        ) {
            Param($Index, $Expected)
            $Actual = (Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md")[$Index]
            $Actual.Replace('```', '`') | Should -BeExactly $Expected
        } 

        It "Should *update* Get-AFunction.md file with new parameter and preserve md modification." {
            $NewSynopsisContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam."

            # modifiy Get-AFunction.md by adding a new parameter
            $NewGetAFunctionMDContent = Get-Item -Path "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" | `
                Get-Content -Raw 

            $NewGetAFunctionMDContent = $NewGetAFunctionMDContent.Replace("{{Fill in the Synopsis}}", $NewSynopsisContent)

            Set-Content -Path "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Value $NewGetAFunctionMDContent


            # modifiy Get-AFunction.md by adding a synopsis
            Clear-Content "$($TestSupportModule.MockDirectoryPath)\src\Get-AFunction.ps1"

            $NewGetAFunctionPS1Content = @"
function Get-AFunction {
    [CmdletBinding(PositionalBinding = `$false)]
    Param(
        [Parameter(Mandatory = `$false)]
        [String]`$Path,

        [Parameter(Mandatory = `$false)]
        [String]`$Key
    )
    
    Out-String -InputObject `$("Hello, from Get-AFunction!")
}
"@
            Set-Content "$($TestSupportModule.MockDirectoryPath)\src\Get-AFunction.ps1" -Value $NewGetAFunctionPS1Content
            
            Build-PlatyPSMarkdown -Path $($TestSupportModule.MockDirectoryPath)

            $SynopsisContent = (Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md")[10]
            $SynopsisContent | Should -Be $NewSynopsisContent

            $GetAFunctionSyntax = (Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md")[15]
            $GetAFunctionSyntax | Should -Be "Get-AFunction [-Path <String>] [-Key <String>] [<CommonParameters>]"
        }
    }

    Context "As a non-piped call, with a given Name value to create files." {

        # removing FileNames from previous Context block. this context block is to test command 
        # using the 'Name' param (vs 'Path').
        $script:FileNames = $null
        
        It "Should generate correct number of files." {

            Build-PlatyPSMarkdown -Name 'MockModuleB' -NoReImportModule

            $script:FileNames = Get-ChildItem "$($TestSupportModule.MockDirectoryPath)\docs" -Recurse | `
                ForEach-Object {$_.Name} | `
                Sort-Object
            
            $script:FileNames.Count | Should -Be 4
        }

        It "Should generate exact filenames." {
            $script:FileNames | Should -BeExactly $script:Files
        }
    }

    Context "As a non-piped call, test to ensure RemoveSourceAndTestLinks works as expected" {
        
        It "Should not add source and test links." {

            Build-PlatyPSMarkdown -Name 'MockModuleB' -RemoveSourceAndTestLinks -NoReImportModule

            $Actual = Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Raw
            $Actual.Contains('[Get-AFunction.ps1](https:') | Should -Be $false
        }
        
        It "Should add source and test links." {

            Build-PlatyPSMarkdown -Name 'MockModuleB' -NoReImportModule

            $Actual = Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Raw
            $Actual.Contains('[Get-AFunction.ps1](https:') | Should -Be $true
        }
        
        It "Should not add source and test links on first call. And second call, requests them to be added." {

            Build-PlatyPSMarkdown -Name 'MockModuleB' -RemoveSourceAndTestLinks -NoReImportModule
            Build-PlatyPSMarkdown -Name 'MockModuleB' -NoReImportModule

            $Actual = Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Raw
            $Actual.Contains('[Get-AFunction.ps1](https:') | Should -Be $true
        }
        
        It "Should not add source and test links on first call.  Afterwards modify markdown file with other links and second call, requests them to be added." {

            Build-PlatyPSMarkdown -Name 'MockModuleB' -RemoveSourceAndTestLinks -NoReImportModule

            Add-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Value "[Get-BFunction](https://github.com/marckassay/MockModuleB/blob/master/docs/Get-BFunction.md)"

            Build-PlatyPSMarkdown -Name 'MockModuleB' -NoReImportModule

            $Actual = Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Raw

            $Actual.Contains('[Get-AFunction.ps1](https:') | Should -Be $true
            $Actual.Contains('[Get-BFunction](https:') | Should -Be $true
        }
        
        It "Should add source and test links on first call.  Afterwards modify markdown file with other links and second call, requests them to be kept." {

            Build-PlatyPSMarkdown -Name 'MockModuleB' -NoReImportModule

            Add-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Value "[Get-CFunction](https://github.com/marckassay/MockModuleB/blob/master/docs/Get-CFunction.md)"

            Build-PlatyPSMarkdown -Name 'MockModuleB' -NoReImportModule

            $FileContent = Get-Content "$($TestSupportModule.MockDirectoryPath)\docs\Get-AFunction.md" -Raw
            
            $RelatedLinksContent = [regex]::Match($FileContent, '(?<=## RELATED LINKS)[\w\W]*$').Value
            $RelatedLinksContent = $RelatedLinksContent.TrimStart()
            
            $ExpectedRelatedLinksContent = @"
[Get-AFunction.ps1](https://github.com/marckassay/MockModuleB/blob/master/src/Get-AFunction.ps1)

[Get-AFunction.Tests.ps1](https://github.com/marckassay/MockModuleB/blob/master/test/Get-AFunction.Tests.ps1)


[Get-BFunction](https://github.com/marckassay/MockModuleB/blob/master/docs/Get-BFunction.md)
[Get-CFunction](https://github.com/marckassay/MockModuleB/blob/master/docs/Get-CFunction.md)
"@
            $RelatedLinksContent.Trim() | Should -Be $ExpectedRelatedLinksContent.Trim()
        }
    }
}