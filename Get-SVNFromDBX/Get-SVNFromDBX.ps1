##############################################################################
# Get-SVNFromDBX.ps1
# Description: This script retrieves the bootloader SVN information
# from the UEFI DBX database.
#
# v1.0.0 - 20250916
##############################################################################

function Get-SVNFromDBX {
    <#
.SYNOPSIS

Parses the bootloader SVN information from the UEFI DBX database.

.DESCRIPTION

Author: Elizabeth Greene <elizabeth.a.greene@gmail.com>
https://github.com/ElizabethGreene/UEFITools
License: BSD 3-Clause

Forked from work by Matthew Graeber (@mattifestation)
https://gist.github.com/mattifestation/1a0f93714ddbabdbac4ad6bcc0f311f3


.EXAMPLE

Get-SecureBootUEFI dbx | Get-SVNFromDBX

.INPUTS

Microsoft.SecureBoot.Commands.UEFIEnvironmentVariable

Accepts the output of Get-SecureBootUEFI over the pipeline.

.OUTPUTS

Outputs a PSObject consisting of the SVN GUID and values.
#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $Variable
    )

    $Results = @{}

    $SignatureTypeMapping = @{
        'C1C41626-504C-4092-ACA9-41F936934328' = 'EFI_CERT_SHA256_GUID' # Most often used for dbx
        'A5C059A1-94E4-4AA7-87B5-AB155C2BF072' = 'EFI_CERT_X509_GUID'   # Most often used for db
    }

    $SvnOwnerGuid = [Guid]::Parse("9d132b6c-59d5-4388-ab1c-185cfcb2eb92")

    try {
        [System.IO.MemoryStream]$MemoryStream = New-Object System.IO.MemoryStream -ArgumentList @(, $Variable.Bytes)
        [System.IO.BinaryReader]$BinaryReader = New-Object System.IO.BinaryReader -ArgumentList $MemoryStream
    
        # What follows will be an array of EFI_SIGNATURE_LIST structs

        while ($MemoryStream.Position -lt $MemoryStream.Length) {
            $SignatureType = $SignatureTypeMapping[([Guid][Byte[]] $BinaryReader.ReadBytes(16)).Guid]
            $SignatureListSize = $BinaryReader.ReadUInt32()
            $SignatureHeaderSize = $BinaryReader.ReadUInt32()
            $SignatureSize = $BinaryReader.ReadUInt32()

            # Read and discard the signature header, if present
            $SignatureHeader = $BinaryReader.ReadBytes($SignatureHeaderSize)

            # 0x1C is the size of the EFI_SIGNATURE_LIST header
            $SignatureCount = ($SignatureListSize - 0x1C) / $SignatureSize

            1..$SignatureCount | ForEach-Object {
                $SignatureDataBytes = $BinaryReader.ReadBytes($SignatureSize)

                $SignatureOwner = [Guid][Byte[]] $SignatureDataBytes[0..15]

                if ($SignatureType -eq 'EFI_CERT_SHA256_GUID') {
                    if ($SignatureOwner -eq $SvnOwnerGuid) {
                        #After the owner GUID
                        #Byte 0: version (unpacked as a 1-byte unsigned integer with "B").
                        #Bytes 1-16: UUID (16 bytes sliced directly as data[1:17]—Python slicing is end-exclusive, so this captures bytes 1 through 16).
                        #Bytes 17,18. UINT16 minor SVN
                        #Bytes 19-20: UINT16 major SVN
                        #Bytes 21-31: reserved

                        $Version = $SignatureDataBytes[16]
                        if ($Version -ne 1) {
                            throw "Unexpected SVN structure version $Version, an update to the script to support new SVN format is required."
                        }
                        
                        $EntryGuid = New-Object System.Guid -ArgumentList @(, ([Byte[]] $SignatureDataBytes[17..32]))                    
                        # Read numeric SVN parts as integers
                        $MinorSvn = [int][BitConverter]::ToUInt16($SignatureDataBytes, 33)
                        $MajorSvn = [int][BitConverter]::ToUInt16($SignatureDataBytes, 35)                                        
                        $EntryObject = [PSCustomObject]@{
                            Guid  = $EntryGuid
                            Major = $MajorSvn
                            Minor = $MinorSvn
                        }

                        if ($Results.ContainsKey($EntryGuid)) {
                            $Existing = $Results[$EntryGuid]
                            if (($Existing.Major -lt $MajorSvn) -or (($Existing.Major -eq $MajorSvn) -and ($Existing.Minor -lt $MinorSvn))) {
                                $Results[$EntryGuid] = $EntryObject
                            }
                        }
                        else {
                            $Results[$EntryGuid] = $EntryObject
                        }
                    }
                }
            }
        }
    }
    catch {
        throw $_
        return
    }
    finally {
        if ($BinaryReader) { $BinaryReader.Dispose() }
        if ($MemoryStream) { $MemoryStream.Dispose() }
    }
    return $Results.Values | ForEach-Object {
        [PSCustomObject]@{ 
            Guid = [Guid]$_.Guid; 
            Svn  = "{0}.{1}" -f $_.Major, $_.Minor
        } 
    }
}

Get-SecureBootUEFI dbx | Get-SVNFromDBX 

# Trivia
# From https://github.com/microsoft/secureboot_objects/blob/b884b605ec686433531511fbc2c8510e59799aaa/PreSignedObjects/DBX/dbx_info_msft_06_10_25.json
# The GUIDs of each SVN tell which boot binary the SVN references:
#
#"guid": "{9d132b61-59d5-4388-1cab-185c3cb2eb92} == EFI_BOOTMGR_DBXSVN_GUID"
#"description": "Windows Bootmgr SVN",
#"filename": "bootmgfw.efi"
#                  
#"guid": "{e8f82e9d-e127-4158-88a4-4c18abe2f284} == EFI_CDBOOT_DBXSVN_GUID"
#"description": "Windows cdboot SVN",
#"filename": "cdboot.efi"
#
#"guid": "{c999cac2-7ffe-496f-2781-9e2a8a535976} == EFI_WDSMGR_DBXSVN_GUID"
#"description": "Windows wdsmgfw",
#"filename": "wdsmgfw.efi"

# Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that. You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code
