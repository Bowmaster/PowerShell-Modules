function Get-ShortName 
{
<#
.SYNOPSIS

    Get's the ShortName of a directory or file.
.DESCRIPTION

    Get's the ShortName of a directory or file.
.PARAMETER Path

    The path to get the shortname of.  By default, this will return the current directory.
.PARAMETER ReturnObject

    Return a 'Get-Item' object for the output instead of the default string path.
.EXAMPLE

    Get-ShortName
    This will return the shortname, if applicable, to the current directory.
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)"
    Returns:    C:\PROGRA~2
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo\msinfo32.exe"
    Returns:    C:\PROGRA~2\COMMON~1\MICROS~1\MSInfo\msinfo32.exe
.EXAMPLE

    Get-ShortName -Path "C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo\msinfo32.exe" -ReturnObject
    Returns:

            Directory: C:\Program Files (x86)\Common Files\Microsoft Shared\MSInfo


    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----        7/16/2016   7:42 AM         336896 msinfo32.exe
.EXAMPLE

    Get-ChildItem -Path "C:\Program Files\" | foreach-object {$_.FullName}
    Returns the shortname of each file or folder in 'C:\Program Files'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]$Path=(Get-Item ".").FullName,
    [Switch]$ReturnObject
    )
    $Path = (Get-Item $Path).FullName
    $fso = New-Object -ComObject Scripting.FileSystemObject
    $Result = $null
    if ((Get-Item $Path).PSIsContainer){
        $Result = ($fso.GetFolder($Path)).ShortPath
    }else{
        $Result = ($fso.GetFile($Path)).ShortPath
    }
    if ($ReturnObject) {
        $Result = Get-Item $Result
    }
    $Result
}