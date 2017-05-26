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
function Get-ShortName 
{
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


<#
.SYNOPSIS

    Monitors a file and prints any additional content to the console.
    Aliases:  Tail
.DESCRIPTION

    Monitors a file and prints any additional content to the console.
    Aliases:  Tail
.PARAMETER File

    The path of the file to Tail.
.PARAMETER InitialLines

    The amount of lines to load into the console on first read. Default is 0, which will allow for only new content written after the start of the command to be shown.
    Specifying -1 will load all content of the file into the console initially.  This could cause performance impact on larger files.
    Alias:  Lines
.EXAMPLE

    Get-FileTail -File C:\Test.log
    Prints all content of a file that is written after the monitoring starts. 
.EXAMPLE

    Get-FileTail -File C:\Test.log -InitialLines -1
    Prints all existing and new content of a file to the console.
.EXAMPLE

    Get-FileTail -File C:\Test.log -InitialLines 5
    Prints the last 5 lines and new content of a file to the console.
.EXAMPLE

    Tail -File C:\Test.log
    Functions the same as the first example, simply uses the 'Tail' alias for this function.
#>
function Get-FileTail
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$File,
        [Parameter(Mandatory=$false)]
        [Alias("Lines")]
        [int32]$InitialLines=0
    )
    # Using cat instead of Get-Content to further make this 'Linuxy'
    if ($InitialLines -eq -1) {
        Write-Host "Starting monitoring of $File with all existing content to be loaded first." -ForegroundColor Yellow
    }else{
        Write-Host "Starting monitoring of $File with $InitialLines initial lines to be loaded first." -ForegroundColor Yellow
    }
    Write-Host "Press CTRL + C to cancel this operation." -ForegroundColor Yellow
    Write-Host ""
    Write-Host ""
    try {
        cat $File -Wait -Tail $InitialLines
    }
    catch {
        Write-Host ""
        Write-Host ""
        Write-Host "The process was interrupted:" -ForegroundColor Red -BackgroundColor Black
        $_.Exception
    }finally{
        Write-Host ""
        Write-Host ""
        Write-Host "Finished tailing $File" -ForegroundColor Yellow
    }
}
New-Alias -Name Tail -Value Get-FileTail -Scope Global


<#
function New-Shortcut
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source,
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        [Parameter(Mandatory=$false)]
        [string]$ExecutionArgs,
        [Parameter(Mandatory=$false)]
        [string]$Description,
        [Parameter(Mandatory=$false)]
        [Switch]$CreateNestedDirs,
        [Parameter(Mandatory=$false)]
        [Switch]$Overwrite
    )
    # Normalize slashes in Source and Destination
    $Source = $Source.Replace("/","\")
    $Destination = $Destination.Replace("/","\")

    # Create full Source Directory
    if ($Source[0] -match "[A-Z]" -and $Source[1] -match ":" -and $Source[2] -match "\\") {
        # Source is a valid full path, no need to do anything else.
    }else{
        # Destination is not a valid full path, joining the current directory with the specified $Source value.
        $Source = Join-Path((Get-Item ".").FullName, $Source)
    }
    $SourceParent = $Source.Remove($Source.LastIndexOf('\'))

    # Create full Destination Directory
    if ($Destination[0] -match "[A-Z]" -and $Destination[1] -match ":" -and $Destination[2] -match "\\") {
        # Destination is a valid full path, no need to do anything else.
    }else{
        # Destination is not a valid full path, joining the current directory with the specified $Destination value.
        $Destination = Join-Path((Get-Item ".").FullName, $Destination)
    }
    $DestParent = $Destination.Remove($Destination.LastIndexOf('\'))
    
    # Check for Existence of Destination's Parent Directory
    if (Test-Path $DestParent) {
        # Parent exists, no need to do anything else.
    }else {
        if ($CreateNestedDirs) {
            try {
                New-Item -ItemType Directory -Path $DestParent
            }
            catch {
                Write-Eror "An error occured attempting to created the nested path for the shortcut. Please check your paths and permissions and try again."
                exit
            }
        }else{
            Write-Error "The parent directory for the requested shorcut does not exist and -CreateNestedDirs was not specified. The process cannot continue."
            exit
        }
    }

    # Check if Destination Exists
    if (Test-Path $Destination) {
        # Destination Exists
        if ($Overwrite) {
            Remove-Item $Destination -Force
        }else {
            Write-Error "The Destination shortcut already exists and -Overwrite was not specified. The process cannot continue."
            Exit
        }
    }

    # Check is Source Exists and Create Shortcut if So
    if (Test-Path $Source) {
        # Source Exists
        try {
            # All pre-checks and pre-process items completed successfully, proceeding with shortcut creation.
            $Shell = New-Object -ComObject ("WScript.Shell")
            $ShortCut = $Shell.CreateShortcut($Destination)
            $ShortCut.TargetPath=$Source
            if ($ExecutionArgs) {
            $ShortCut.Arguments= $ExecutionArgs  
            }
            $ShortCut.WorkingDirectory = $SourceParent
            # $ShortCut.WindowStyle = 1
            # $ShortCut.Hotkey = "CTRL+SHIFT+F"
            $ShortCut.IconLocation = "$Source, 0"
            if ($Description) {
                $ShortCut.Description = $Description 
            }
            $ShortCut.Save()
            $ShortCut = $null
            $Shell = $null
        }
        catch {
            # An Error Occured
            Write-Error "An error occured while creating the shortcut:"
            Write-Error $_
        }
    }else{
        Write-Error "The Source file or folder does not exist, please check your inputs and try again."
    }
}
#>


<#
.SYNOPSIS
A more robust way to write log files.  Appends date/time information and has support for log rollover based on size.

.DESCRIPTION
A more robust way to write log files.  Appends date/time information and has support for log rollover based on size.

.PARAMETER LogPath
The absolute or relative path to the logfile. Required.
Alias = Path

.PARAMETER LineText
The text to write. If ommited, a blank line will be written.
Alias = Text

.PARAMETER WriteHost
Allows for the text written to the log file to also be output to the console.
Alias = WH

.PARAMETER Color
If -WriteHost is specified, allows you to specify the valid color to output to the console. If no Color is selected, white will be the default.
Alias = C

.EXAMPLE
Write-LogFile -Logpath "C:\Windows\Temp" -LineText "This is a test."

.EXAMPLE
Write-LogFile -Logpath "C:\Windows\Temp" -LineText "This is a test." -WriteHost

.EXAMPLE
Write-LogFile -Logpath "C:\Windows\Temp" -LineText "This is a test." -WriteHost -Color Cyan

.EXAMPLE
Write-LogFile "C:\Windows\Temp" "This is a test." $true Magenta

.EXAMPLE
WLF "C:\Windows\Temp" "This is a test."

.NOTES
This is using the .net streamwriter class so it should be capable of very quick write operations without error or line drop.
#>
function Write-LogFile
{
[CmdletBinding()]
param(
[Parameter(Mandatory=$true,Position=0)]
[Alias("Path")]
[string]$LogPath,
[Parameter(Mandatory=$false,Position=1)]
[Alias("Text")]
[string]$LineText="",
[Parameter(Mandatory=$false,Position=2,ParameterSetName=1)]
[Alias("WH")]
[Switch]$WriteHost,
[Parameter(Mandatory=$false,Position=3,ParameterSetName=1)]
[Alias("C")]
[ConsoleColor]$Color="White"
) 
    $ErrorCount = 0
    do {
        try {
            $LogPath = [System.IO.Path]::GetFullPath($LogPath)
            $LogDirectory = [System.IO.Path]::GetDirectoryName($LogPath)
            $DirExisted = $true
            $FileExisted = $true
            $fInfo = [System.IO.FileInfo]($LogPath)
            $User = $ENV:USERNAME
            $Domain = $ENV:USERDOMAIN
            if ($ENV:USERDOMAIN -eq $ENV:COMPUTERNAME) {
                $Domain = "."
            }
            $Ext = [System.IO.Path]::GetExtension($LogPath)
            if((Test-Path $LogDirectory) -eq $False){
                New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
                $DirExisted = $False
            }
            if ((Test-Path $LogPath) -eq $False) {
                New-Item -ItemType File -Path $LogPath | Out-Null
                $FileExisted = $False
                $sw = New-Object System.IO.StreamWriter($LogPath,$true)
            }else {
                $sw = New-Object System.IO.StreamWriter($LogPath,$true)
                $MaxSize = 5242880
                if ($finfo.Length -gt $MaxSize) {
                    # fInfo.Length -gt 1048576 for 1MB
                    # fInfo.Length -gt 5242880 for 1MB
                    $LogFileRollover = $LogPath.Replace($Ext,"_") + (Get-Date).ToString().Replace("/","-").Replace(":",".").Replace(" ", "_") + "$($Ext)_"
                    $sw.WriteLine("Log file is greater than " + $MaxSize / 1MB + " MB, beginning new log file.  Existing log file will be renamed to " + $LogFileRollover)
                    $sw.WriteLine("End log")
                    $sw.Close()
                    Rename-Item -Path $LogPath -NewName $LogFileRollover
                    Start-Sleep -Milliseconds 500
                    New-Item -ItemType File $LogPath | Out-Null
                    $FileExisted = $False
                    $sw = $null
                    $sw = New-Object System.IO.StreamWriter($LogPath,$true)
                }   
            }
            if ($DirExisted -eq $false) {
                $WriteLine = (Get-Date).ToString() + " $Domain\$User" + "  ::::  " + "Creating directory " + $LogDirectory
                $sw.WriteLine($WriteLine)
                if ($WriteHost) {
                    Write-Host $WriteLine -ForegroundColor $Color
                }
                $WriteLine = $null
            }
            if ($FileExisted -eq $False) {
                $WriteLine = (Get-Date).ToString() + " $Domain\$User" + "  ::::  " + "Creating file " + $LogPath
                $sw.WriteLine($WriteLine)
                if ($WriteHost) {
                    Write-Host $WriteLine -ForegroundColor $Color
                }
                $WriteLine = $null
                if ($LogFileRollover) {
                    $WriteLine = (Get-Date).ToString() + " $Domain\$User" + "  ::::  " + "Previous log: $LogFileRollover"
                    $sw.WriteLine($WriteLine)
                    if ($WriteHost) {
                        Write-Host $WriteLine -ForegroundColor $Color
                    }
                    $WriteLine = $null
                }
            }
            $WriteLine = (Get-Date).ToString() + " $Domain\$User" + "  ::::  " + $LineText
            $sw.WriteLine($WriteLine)
            $sw.Close()
            $sw.Dispose()
            $sw = $null
            if ($WriteHost) {
                Write-Host $WriteLine -ForegroundColor $Color
            }
            $WriteLine = $null
            $ErrorCount = 2
        }
        catch [System.Exception] {
            $ErrorCount++
            if ($ErrorCount -eq 2) {
                Write-Error "Multiple errors occured while attempting to write the log:"
                Write-Error $_
            }
        }
    } until ($ErrorCount -eq 2)
}
New-Alias -Name wlf -Value Write-LogFile -Scope Global