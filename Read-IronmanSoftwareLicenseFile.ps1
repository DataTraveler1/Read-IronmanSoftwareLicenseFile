Function Read-IronmanSoftwareLicenseFile {
<#
    .SYNOPSIS
    Displays the contents of your Ironman Software License File

    .DESCRIPTION
    Displays the contents of your Ironman Software License File
    Not affiliated with Ironman Software Inc. Use this at your own risk.

    .PARAMETER PathToLicense
    This must be a complete path to a license.txt or license.lic file. 

    .PARAMETER FindMyPoshLicenseFile
    Attempts to use "$env:APPDATA\PowerShell Pro Tools\license.lic"

    .LINK
    Online version: https://github.com/DataTraveler1/Read-IronmanSoftwareLicenseFile

#>
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$FindMyPoshLicense,
        [Parameter(Mandatory=$false)]
        [string]$PathToLicense
    )    
    [int32]$PathToLicense_length = $PathToLicense.Length
    If(($FindMyPoshLicense -ne $true) -and ($PathToLicense_length -eq 0))
    {
        [string]$PathToLicense = Read-Host -Prompt 'Please provide the path to license.txt or license.lic (Example: c:\temp\license.txt)'
    }
    ElseIf(($null -ne $FindMyPoshLicense) -and ($PathToLicense_length -eq 0))
    {
        If(( Test-Path -Path "$env:APPDATA\PowerShell Pro Tools\license.lic") -eq $true)
        {
            [string]$PathToLicense = "$env:APPDATA\PowerShell Pro Tools\license.lic"
            Write-Host $PathToLicense
        }        
    }
    ElseIf(($FindMyPoshLicense -eq $true) -and ($PathToLicense_length -gt 0))
    {
        Write-Host "Error: You can't specify -FindMyPoshLicense with -PathToLicense"
        Return
    }
    [boolean]$license_file_exists = Test-Path -Path $PathToLicense
    If ( $license_file_exists -eq $false) {
        Write-Host "Error: License file [$PathToLicense] does not exist"
        Return
    }
    $Error.Clear()
    Try {
        [array]$license_content = Get-Content -Path "$PathToLicense" -Force
    }
    Catch {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } | Select-Object -First 1 | Select-Object -ExpandProperty Exception
        Write-Host "Error: Get-Content failed to get the license file [$PathToLicense] due to [$error_message]"
        Return
    }
    [int32]$license_content_line_count = $license_content.count
    If( $license_content_line_count -eq 0)
    {
        Write-Host "Error: The license file [$PathToLicense]"
    }
    ElseIf( $license_content_line_count -gt 1)
    {
        Write-Host "Error: How does the license file contain more than 1 line? Something is off here. Please fix the file and try again."
        Return
    }    
    $Error.Clear()
    Try {
        [xml]$license_xml_object = [xml]$license_content
    }
    Catch {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } | Select-Object -First 1 | Select-Object -ExpandProperty Exception
        Write-Host "Error: Casting the license content string [$license_content] failed due to [$error_message]"
        Return
    }
    [string]$terms = $license_xml_object.License.Terms
    [int32]$terms_length = $terms.Length
    If( $terms_length -eq 0)
    {
        Write-Host "Error: The Terms node from the imported XML file is somehow 0 characters in length. Please fix this."
        Return
    }
    If( $terms -notmatch '^[a-zA-Z0-9/+ ]{1,}[=]{0,2}$')
    {
        Write-Host "Error: The value of the Terms node from the imported XML file [$terms] does not match the expected base64 format. Please look into this."
        Return
    }
    $Error.Clear()
    Try
    {
        [string]$terms_decoded = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($terms))) -replace [char]65279
    }
    Catch
    {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } | Select-Object -First 1 | Select-Object -ExpandProperty Exception
        Write-Host "Error: Decoding the license terms (base64) content string [$terms] failed due to [$error_message]"
        Return
    }
    $Error.Clear()
    Try
    {
        [System.Xml.XmlLinkedNode]$terms_xml = ([xml]$terms_decoded) | Select-Object -ExpandProperty LicenseTerms
    }
    Catch
    {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } | Select-Object -First 1 | Select-Object -ExpandProperty Exception
        Write-Host "Error: Casting the license -terms- content string [$terms_decoded] failed due to [$error_message]"
        Return
    }
    $Error.Clear()
    Try
    {
        [void]$terms_xml.RemoveAttributeAt(0) # removes 'xsi' attribute
        [void]$terms_xml.RemoveAttributeAt(0) # removes 'xsd' attribute
    }
    Catch
    {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } | Select-Object -First 1 | Select-Object -ExpandProperty Exception
        Write-Host "Error: Removing the xsi and xsd attributes from the [System.Xml.XmlLinkedNode] failed due to  [$error_message]"
        Return
    }
    $Error.Clear()
    Try
    {
        [PSCustomObject]$terms_object = $terms_xml | ConvertTo-Csv | ConvertFrom-CSV
    }    
    Catch
    {
        [array]$error_clone = $Error.Clone()
        [string]$error_message = $error_clone | Where-Object { $null -ne $_.Exception } | Select-Object -First 1 | Select-Object -ExpandProperty Exception
        Write-Host "Error: Converting the license terms XML linked node object to a PSCustomObject failed due to  [$error_message]"
        Return
    }
    Return $terms_object
}
