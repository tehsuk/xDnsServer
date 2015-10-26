if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..).Path

$ModuleName = "MSFT_xDnsServerPrimaryZone"
Import-Module (Join-Path $RepoRoot "DSCResources\$ModuleName\$ModuleName.psm1")

Describe 'xDnsServerPrimaryZone' {
    InModuleScope $ModuleName {

        ## Stub DnsServer module cmdlets
        function Get-DnsServerZone { }
        function Add-DnsServerPrimaryZone { param ( $Name ) }
        function Set-DnsServerPrimaryZone { [CmdletBinding()] param (
            [Parameter(ValueFromPipeline)] $Name,
            [Parameter(ValueFromPipeline)] $DynamicUpdate,
            [Parameter(ValueFromPipeline)] $ZoneFile ) }
        function Remove-DnsServerZone { }

        $testZoneName = 'example.com';
        $testZoneFile = 'example.com.dns';
        $testDynamicUpdate = 'None';
        $testParams = @{ Name = $testZoneName; }

        $fakeDnsFileZone = [PSCustomObject] @{
            DistinguishedName = $null;
            ZoneName = $testZoneName;
            ZoneType = 'Primary';
            DynamicUpdate = $testDynamicUpdate;
            ReplicationScope = 'None';
            DirectoryPartitionName = $null;
            ZoneFile = $testZoneFile;
        }

        Mock -CommandName 'Assert-Module' -MockWith { }

        Context 'Validates Get-TargetResource Method' {

            It 'Returns a hashtable' {
                $targetResource = Get-TargetResource @testParams -ZoneFile 'example.com.dns';
                $targetResource -is [System.Collections.Hashtable] | Should Be $true;
            }

            It 'Returns "Ensure" = "Present" when DNS zone exists' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone; }
                $targetResource = Get-TargetResource @testParams -ZoneFile 'example.com.dns';
                $targetResource.Ensure | Should Be 'Present';
            }

             It 'Returns "Ensure" = "Absent" when DNS zone does not exists' {
                Mock -CommandName Get-DnsServerZone -MockWith { }
                $targetResource = Get-TargetResource @testParams -ZoneFile 'example.com.dns';
                $targetResource.Ensure | Should Be 'Absent';
            }

        } #end context Validates Get-TargetResource Method

        Context 'Validates Test-TargetResource Method' {

            It 'Returns a boolean' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone; }
                $targetResource =  Test-TargetResource @testParams -ZoneFile 'example.com.dns';
                $targetResource -is [System.Boolean] | Should Be $true;
            }

            It 'Returns $true when DNS zone exists and "Ensure" = "Present"' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone; }
                Test-TargetResource @testParams -Ensure Present -ZoneFile 'example.com.dns' | Should Be $true;
            }

            It 'Returns $true when DNS zone does not exist and "Ensure" = "Absent"' {
                Mock -CommandName Get-DnsServerZone -MockWith { }
                Test-TargetResource @testParams -Ensure Absent -ZoneFile 'example.com.dns' | Should Be $true;
            }

            It 'Returns $true when DNS zone "DynamicUpdate" is correct' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone; }
                Test-TargetResource @testParams -Ensure Present -DynamicUpdate $testDynamicUpdate -ZoneFile 'example.com.dns' | Should Be $true;
            }

            It 'Returns $false when DNS zone exists and "Ensure" = "Absent"' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone; }
                Test-TargetResource @testParams -Ensure Absent -ZoneFile 'example.com.dns' | Should Be $false;
            }

            It 'Returns $false when DNS zone does not exist and "Ensure" = "Present"' {
                Mock -CommandName Get-DnsServerZone -MockWith { }
                Test-TargetResource @testParams -Ensure Present -ZoneFile 'example.com.dns' | Should Be $false;
            }

            It 'Returns $false when DNS zone "DynamicUpdate" is incorrect' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone; }
                Test-TargetResource @testParams -Ensure Present -DynamicUpdate 'NonsecureAndSecure' -ZoneFile $testZoneFile | Should Be $false;
            }

            It 'Returns $false when DNS zone "ZoneFile" is incorrect' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone; }
                Test-TargetResource @testParams -Ensure Present -DynamicUpdate $testDynamicUpdate -ZoneFile 'nonexistent.com.dns' | Should Be $false;
            }

        } #end context Validates Test-TargetResource Method

        Context 'Validates Set-TargetResource Method' {

            It 'Calls "Add-DnsServerPrimaryZone" when DNS zone does not exist and "Ensure" = "Present"' {
                Mock -CommandName Get-DnsServerZone -MockWith { }
                Mock -CommandName Add-DnsServerPrimaryZone -ParameterFilter { $Name -eq $testZoneName } -MockWith { }
                Set-TargetResource @testParams -Ensure Present -DynamicUpdate $testDynamicUpdate -ZoneFile $testZoneFile;
                Assert-MockCalled -CommandName Add-DnsServerPrimaryZone -ParameterFilter { $Name -eq $testZoneName } -Scope It;
            }

            It 'Calls "Remove-DnsServerZone" when DNS zone does exist and "Ensure" = "Absent"' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone }
                Mock -CommandName Remove-DnsServerZone -MockWith { }
                Set-TargetResource @testParams -Ensure Absent -DynamicUpdate $testDynamicUpdate -ZoneFile $testZoneFile;
                Assert-MockCalled -CommandName Remove-DnsServerZone -Scope It;
            }

            It 'Calls "Set-DnsServerPrimaryZone" when DNS zone "DynamicUpdate" is incorrect' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone }
                Mock -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $DynamicUpdate -eq 'NonsecureAndSecure' } -MockWith { }
                Set-TargetResource @testParams -Ensure Present -DynamicUpdate 'NonsecureAndSecure' -ZoneFile $testZoneFile;
                Assert-MockCalled -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $DynamicUpdate -eq 'NonsecureAndSecure' } -Scope It;
            }

            It 'Calls "Set-DnsServerPrimaryZone" when DNS zone "ZoneFile" is incorrect' {
                Mock -CommandName Get-DnsServerZone -MockWith { return $fakeDnsFileZone }
                Mock -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $ZoneFile -eq 'nonexistent.com.dns' } -MockWith { }
                Set-TargetResource @testParams -Ensure Present -DynamicUpdate $testDynamicUpdate -ZoneFile 'nonexistent.com.dns';
                Assert-MockCalled -CommandName Set-DnsServerPrimaryZone -ParameterFilter { $ZoneFile -eq 'nonexistent.com.dns' } -Scope It;
            }

        } #end context Validates Set-TargetResource Method

    }
}
