# Get-SVNFromDBX.ps1

Description: This script retrieves the bootloader SVN information from the UEFI DBX database.

## Author / Attribution

Elizabeth Greene <elizabeth.a.greene@gmail.com>
<https://github.com/ElizabethGreene/UEFITools>

Forked from work by Matthew Graeber (@mattifestation)
<https://gist.github.com/mattifestation/1a0f93714ddbabdbac4ad6bcc0f311f3>

## License

License: BSD 3-Clause <https://opensource.org/license/BSD-3-clause>

Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that. You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code

## Usage

If necessary, enable running PowerShell scripts, and run "Get-SVNFromDBX.ps1" in an administrative PowerShell prompt.

On a system with no SVN entries in the UEFI Secureboot db, no results will be returned.

```PowerShell
PS C:\WINDOWS\system32> C:\Users\egreene\Desktop\Get-SVNFromDBX.ps1

```

On a system with SVN entries, the highest unique value will be returned for each bootloader GUID.  E.g.

```PowerShell
PS C:\WINDOWS\system32> C:\Users\egreene\Desktop\Get-SVNFromDBX.ps1

Guid                                 Svn
----                                 ---
9d132b61-59d5-4388-ab1c-185c3cb2eb92 7.0
e8f82e9d-e127-4158-a488-4c18abe2f284 3.0
c999cac2-7ffe-496f-8127-9e2a8a535976 3.0
```
