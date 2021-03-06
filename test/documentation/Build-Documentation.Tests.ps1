using module ..\.\TestRunnerSupportModule.psm1

Describe "Test Build-Documentation" {
    BeforeAll {
        $TestSupportModule = [TestRunnerSupportModule]::new('MockModuleB')
        $MockDocDirectoryPath = Join-Path -Path $TestSupportModule.MockDirectoryPath -ChildPath 'docs' -Resolve

        # this test file needs the .git repo but not the docs folder
        Remove-Item -Path $MockDocDirectoryPath -Recurse
    }
    
    AfterAll {
        $TestSupportModule.Teardown()
    }

    Context "Given a value for Path, this function internally contains the following pipeline: Build-PlatyPSMarkdown | New-ExternalHelpFromPlatyPSMarkdown | Update-ReadmeFromPlatyPSMarkdown" {

        $Files = "Get-AFunction.md", "Get-BFunction.md", "Get-CFunction.md", "Set-CFunction.md" | `
            Sort-Object
        
        # NOTE: if this functions re-imports, it will import into a different scope or session. 
        # Although it will still pass, it will write warnings and errors
        Build-Documentation -Path $TestSupportModule.MockDirectoryPath -NoReImportModule

        $FileNames = Get-ChildItem $MockDocDirectoryPath -Recurse | `
            ForEach-Object {$_.Name} | `
            Sort-Object

        It "Should generate correct number of files." {
            $FileNames.Count | Should -Be 4
        }

        It "Should generate exactly filenames." {
            $FileNames | Should -BeExactly $Files
        }

        It "Should have modified the new ReadMe file." {
            (Get-Content "$($TestSupportModule.MockDirectoryPath)\README.md" -Raw) -like "*API*" | Should -Be $true
        }

        It "Should modify Get-AFunction.md file at line number <Index> with: {<Expected>} " -TestCases @(
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
            $Actual = (Get-Content "$MockDocDirectoryPath\Get-AFunction.md")[$Index]
            $Actual.Replace('```', '`') | Should -BeExactly $Expected
        }

        # TODO: comment this out, since this will need to be in a different context. context of updating
        # existing files
        <# 
        It "Should modify README.md file at line number <Index> with: {<Expected>} " -TestCases @(
            @{ Index = 0; Expected = "" },
            @{ Index = 1; Expected = "" },
            @{ Index = 2; Expected = "## Functions" },
            @{ Index = 3; Expected = "" },
            @{ Index = 4; Expected = "#### [```Get-AFunction```]()" }
            @{ Index = 5; Expected = "" }
            @{ Index = 6; Expected = "    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam." }
            @{ Index = 7; Expected = " " }
            @{ Index = 8; Expected = "#### [```Get-BFunction```]()" }
        ) {
            Param($Index, $Expected)
            $Actual = (Get-Content "$TestDrive\MockModuleB\README.md")[$Index]
            $Actual.Replace('```', '`') | Should -BeExactly $Expected
        } #>
    }
}
