####Jeremy Hall's Powershell Profile####
########################################
Write-Output 'Just Loading Some Stuff in the Background...'
# Import AWS PSModule
Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Setup Alias below
function ls_alias { wsl ls --color=auto -hF $args }
Set-Alias -Name ls -Value ls_alias -Option AllScope

oh-my-posh --init --shell pwsh --config C:\Users\%USERNAME%\Documents\WindowsPowerShell/jandedobbeleer.omp.json | Invoke-Expression

# Custom Alias Setup Below
Set-Alias -Name k -Value kubectl -Description "kubectl - or K8s Control Executable"
Set-Alias -Name gpod -Value 'k get pod' -Description "Use kubectl to list Pods"
Set-Alias -Name grs -Value 'kubectl get rs' -Description "Get K8s Replication Sets"
Set-Alias -Name kdeploy -Value 'kubectl -f apply' -Description "Runs k8s -f apply - provide a yaml file to deploy it"
Set-Alias -Name pm -Value podman -Description "Alias for the Podman executable"
Set-Alias -Name d -Value docker -Description "Docker Executable Alias"

#Autocomplete in Pshell code start

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Chord UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Chord DownArrow -Function HistorySearchForward

# Custom Alias #

# LOAD CUSTOM MODULES AND SCRIPTS #

# Berkshelf #
#chef shell-init powershell | Invoke-Expression
#$env:BERKSHELF_PATH="C:\working\berkshelf"

# Load Posh-Git #
$ModPath = $env:PSModulePath.split(";")[0]
if (!(test-path $ModPath)) {
mkdir $ModPath
}
$PoshGitPath = Join-Path $ModPath "posh-git"
if (!(test-path $PoshGitPath)) {
   push-location $ModPath
   try {
       if (Test-Connection https://github.com/dahlbyk/posh-git.git -Quiet -Count 1 -ErrorAction SilentlyContinue) {
           Invoke-Expression git clone https://github.com/dahlbyk/posh-git.git "posh-git"
       } else {
           write-host "Unable to reach https://github.com/dahlbyk/posh-git.git"
       }
   } catch {
       write-host "Unable to download posh-git"
   } finally {
       pop-location
   }
}
if ((Get-Module posh-git -ListAvailable).count -eq 1) {
   import-module posh-git -DisableNameChecking
   function global:prompt {
       $realLASTEXITCODE = $LASTEXITCODE

       Write-Host($pwd.ProviderPath) -nonewline

       Write-VcsStatus

       $global:LASTEXITCODE = $realLASTEXITCODE
       return "> "
   }
}

# Get and Show Data for FastFetch (IF YOU DO NOT HAVE FASTFETCH INSTALLED, IT WILL NOT WORK)
# Install FastFetch using WinGet | winget install fastfetch
# Install FastFetch with Scoop |  scoop install fastfetch
# https://github.com/fastfetch/fastfetch
#fastfetch

function Invoke-Starship-PreCommand {
    $host.ui.Write("🚀")
}
# edit $PROFILE
function Invoke-Starship-PreCommand {
  $host.ui.RawUI.WindowTitle = "$env:USERNAME@$env:COMPUTERNAME`: $pwd `a"
}
Invoke-Expression (&starship init powershell)

##############################################################################
## Get-FileHash
##############################################################################

<#

.SYNOPSIS

Get the hash of an input file.

.EXAMPLE

Get-FileHash myFile.txt
Gets the hash of a specific file

.EXAMPLE

dir | Get-FileHash
Gets the hash of files from the pipeline

.EXAMPLE

Get-FileHash myFile.txt -Hash SHA1
Gets the has of myFile.txt, using the SHA1 hashing algorithm

#>
Function get-filehash {
param(
    ## The path of the file to check
    $Path,

    ## The algorithm to use for hash computation
    [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
    $HashAlgorithm = "MD5"
)

Set-StrictMode -Version Latest

## Create the hash object that calculates the hash of our file.
$hashType = [Type] "System.Security.Cryptography.$HashAlgorithm"
$hasher = $hashType::Create()

## Create an array to hold the list of files
$files = @()

## If they specified the file name as a parameter, add that to the list
## of files to process
if($path)
{
    $files += $path
}
## Otherwise, take the files that they piped in to the script.
## For each input file, put its full name into the file list
else
{
    $files += @($input | Foreach-Object { $_.FullName })
}

## Go through each of the items in the list of input files
foreach ($file in $files)
{
    ## Skip the item if it is not a file
    if(-not (Test-Path $file -Type Leaf)) { continue }

    ## Convert it to a fully-qualified path
    $filename = (Resolve-Path $file).Path

    ## Use the ComputeHash method from the hash object to calculate
    ## the hash
    $inputStream = New-Object IO.StreamReader $filename
    $hashBytes = $hasher.ComputeHash($inputStream.BaseStream)
    $inputStream.Close()

    ## Convert the result to hexadecimal
    $builder = New-Object System.Text.StringBuilder
    $hashBytes | Foreach-Object { [void] $builder.Append($_.ToString("X2")) }

    ## Return a custom object with the important details from the
    ## hashing
    $output = New-Object PsObject -Property @{
        Path = ([IO.Path]::GetFileName($file));
        HashAlgorithm = $hashAlgorithm;
        HashValue = $builder.ToString()
    }

    $output
}
}
Function global:Start-RDP {
    param(
        [string]$Server = "",
        [int]$Width = "",
        [int]$Height = "",
        [string]$Path = "",
        [switch]$Console,
        [switch]$Admin,
        [switch]$Fullscreen,
        [switch]$Public,
        [switch]$Span
    )

    begin {
        $arguments = ""
        $dimensions = ""
        $processed = $false

        if ($admin) {
            $arguments += "/admin "
        } elseif ($console) {
            $arguments += "/console "
        }
        if ($fullscreen) {
            $arguments += "/f "
        }
        if ($public) {
            $arguments += "/public "
        }
        if ($span) {
            $arguments += "/span "
        }

        if ($width -and $height) {
            $dimensions = "/w:$width /h:$height"
        }
    }

    process {
        Function script:executePath([string]$path) {
            Invoke-Expression "mstsc.exe '$path' $dimensions $arguments"
        }
        Function script:executeArguments([string]$Server) {
            Invoke-Expression "mstsc.exe /v:$server $dimensions $arguments"
        }

        if ($_) {
            if ($_ -is [string]) {
                if ($_ -imatch '\.rdp$') {
                    if (Test-Path $_) {
                        executePath $_
                        $processed = $true
                    } else {
                        throw "Path does not exist."
                    }
                } else {
                    executeArguments $_
                    $processed = $true
                }
            } elseif ($_ -is [System.IO.FileInfo]) {
                if (Test-Path $_.FullName) {
                    executePath $_.FullName
                    $processed = $true
                } else {
                    throw "Path does not exist."
               }
            } elseif ($_.Path) {
                if (Test-Path $_.Path) {
                    executePath $_.Path
                    $processed = $true
                } else {
                    throw "Path does not exist."
                }
            } elseif ($_.DnsName) {
                executeArguments $_.DnsName
                $processed = $true
            } elseif ($_.Server) {
                executeArguments $_.Server
                $processed = $true
            } elseif ($_.ServerName) {
                executeArguments $_.ServerName
                $processed = $true
            } elseif ($_.Name) {
                executeArguments $_.Name
                $processed = $true
            }
        }
    }

    end {
        if ($path) {
            if (Test-Path $path) {
                Invoke-Expression "mstsc.exe '$path' $dimensions $arguments"

            } else {
                throw "Path does not exist."
            }
        } elseif ($server) {
            Invoke-Expression "mstsc.exe /v:$server $dimensions $arguments"
        } elseif (-not $processed) {
            Invoke-Expression "mstsc.exe $dimensions $arguments"
        }
    }
}
function Trace-Route
{
   param(
   # The URL to trace
   [Parameter(Mandatory=$true)]
   [Uri]$Url,
   # The timeout for the request, in milliseconds
   [Timespan]$Timeout = "0:0:0.25",
   # The maximum number of hops for the trace route
   [Int]$MaximumHops = 32
   )

   process {
       Invoke-Expression "tracert -w $($timeOut.TotalMilliseconds) -h $MaximumHops $url" |
           Where-Object {
               if ($_ -match "[.+]") {
                   $destination
                   try {
                       $destination = [IpAddress]$_.Split("[]",[StringSplitOptions]"RemoveEmptyEntries")[-1]
                   } catch {
                       return $false
                   }
               }
               $true
           } |
           Where-Object {
               if ($_ -like "*Request timed out.*") {
                   throw "Request timed Out"
               }
               return $true
           } |
           Foreach-Object {
               if ($_ -like "*ms*" ) {
                   $chunks = $_ -split "  " | Where-Object { $_ }
                   $destAndip = $chunks[-1]
                   $dest, $ip = $destAndip.Replace("[", "").Replace("]","") -split " "

                   if (-not $ip) {
                       $ip = $dest
                       $dest = ""
                   }

                   $ip = @($ip)[0].Trim() -as [IPAddress]


                   if ($chunks[1] -eq '*' -and $chunks[2] -eq '*' -and $chunks[3] -eq '*') {
                       Write-Error "Request Timed Out"
                       return
                   }
                   $trace = New-Object Object
                   $time1 = try { [Timespan]::FromMilliseconds($chunks[1].Replace("<","").Replace(" ms", ""))} catch {}
                   $time2 = try { [Timespan]::FromMilliseconds($chunks[1].Replace("<","").Replace(" ms", ""))} catch {}
                   $time3 = try { [Timespan]::FromMilliseconds($chunks[1].Replace("<","").Replace(" ms", ""))} catch {}
                   $trace |
                       Add-Member NoteProperty HopNumber ($chunks[0].Trim() -as [uint32]) -PassThru |
                       Add-Member NoteProperty Time1 $time1 -PassThru |
                       Add-Member NoteProperty Time2 $time2 -PassThru |
                       Add-Member NoteProperty Time3 $time3 -PassThru |
                       Add-Member NoteProperty Ip $ip -PassThru |
                       Add-Member NoteProperty Host $dest -PassThru |
                       Add-Member NoteProperty DestinationUrl $url -PassThru |
                       Add-Member NoteProperty DestinationIP $destination -PassThru

               }
           }
   }
}

function Restart-IISAppPool {
   [CmdletBinding(SupportsShouldProcess=$true)]
param(
      [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory= $true, Position=0)]
      [Alias("Name","Pool")]
      [String[]]$AppPool
   ,
      [Parameter(ValueFromPipelineByPropertyName=$true, Position=1)]
      [Alias("CN","Server","__Server")]
      [String]$ComputerName
   ,
      [Parameter()]
      [System.Management.Automation.Credential()]
      $Credential = [System.Management.Automation.PSCredential]::Empty
   )

   begin {
      if ($Credential -and ($Credential -ne [System.Management.Automation.PSCredential]::Empty)) {
         $Credential = $Credential.GetNetworkCredential()
      }
      Write-Debug ("BEGIN:`n{0}" -f ($PSBoundParameters | Out-String))

      $Skip = $false
      ## Need to test for AppPool existence (it's not defined in BEGIN if it's piped in)
      if($PSBoundParameters.ContainsKey("AppPool") -and $AppPool -match "\*") {
        $null = $PSBoundParameters.Remove("AppPool")
        $null = $PSBoundParameters.Remove("WhatIf")
        $null = $PSBoundParameters.Remove("Confirm")
        Write-Verbose "Searching for AppPools matching: $($AppPool -join ', ')"

        Get-WmiObject IISApplicationPool -Namespace root\MicrosoftIISv2 -Authentication PacketPrivacy @PSBoundParameters |
        Where-Object { @(foreach($pool in $AppPool){ $_.Name -like $Pool -or $_.Name -like "W3SVC/APPPOOLS/$Pool" }) -contains $true } |
        Restart-IISAppPool
        $Skip = $true
      }
      $ProcessNone = $ProcessAll = $false;
   }
   process {
      Write-Debug ("PROCESS:`n{0}" -f ($PSBoundParameters | Out-String))

      if(!$Skip) {
        $null = $PSBoundParameters.Remove("AppPool")
        $null = $PSBoundParameters.Remove("WhatIf")
        $null = $PSBoundParameters.Remove("Confirm")
         foreach($pool in $AppPool) {
            Write-Verbose "Processing $Pool"
            if($PSCmdlet.ShouldProcess("Would restart the AppPool '$Pool' on the '$(if($ComputerName){$ComputerName}else{'local'})' server.", "Restart ${Pool}?", "Restarting IIS App Pools on $ComputerName")) {
               Write-Verbose "Restarting $Pool"
               # if($PSCmdlet.ShouldContinue("Do you want to restart $Pool?", "Restarting IIS App Pools on $ComputerName", [ref]$ProcessAll, [ref]$ProcessNone)) {
                 Invoke-WMIMethod Recycle -Path "IISApplicationPool.Name='$Pool'" -Namespace root\MicrosoftIISv2 -Authentication PacketPrivacy @PSBoundParameters
               # }
            }
         }
      }
   }
}

function Search-TextFile {
  param(
    [parameter(mandatory=$true)]$File,
    [parameter(mandatory=$true)]$SearchText
  ) #close param
  if ( !(test-path $File) ) {"File not found:" + $File; break}
  $fullPath = resolve-path $file | select -expand path
  $lines = [system.io.file]::ReadLines($fullPath)
  foreach ($line in $lines) { if ($line -match $SearchText) {$line} }
}

Function Reload
{
$cline = "`"/c start powershell.exe -noexit -c `"Set-Location '{0}'" -f $PWD.path
cmd $cline
Stop-Process -Id $PID
}

function Explore
{
param
    (
        [Parameter(
            Position = 0,
            ValueFromPipeline=$true,
            Mandatory=$true,
            HelpMessage="This is the path to explore..."
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        #First param is the path you're going to explore.
        $Target
    )
$exploriation = New-Object -ComObject shell.application
$exploriation.Explore($Target)
}

Function llm #lock Local machine
{

 $signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool LockWorkStation();
"@
    $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru

    $LockWorkStation::LockWorkStation()|Out-Null
}

# DEFINE: Simple Mathmatical Alias #
function count
{
    BEGIN { $x = 0 }
    PROCESS { $x += 1 }
    END { $x }
}

function product
{
    BEGIN { $x = 1 }
    PROCESS { $x *= $_ }
    END { $x }
}

function sum
{
    BEGIN { $x = 0 }
    PROCESS { $x += $_ }
    END { $x }
}

function average
{
    BEGIN { $max = 0; $curr = 0 }
    PROCESS { $max += $_; $curr += 1 }
    END { $max / $curr }
}


function df {
    $colItems = Get-wmiObject -class "Win32_LogicalDisk" -namespace "root\CIMV2" `
    -computername localhost

    foreach ($objItem in $colItems) {
    	write $objItem.DeviceID $objItem.Description $objItem.FileSystem `
    		($objItem.Size / 1GB).ToString("f3") ($objItem.FreeSpace / 1GB).ToString("f3")
    }
}

# Credit for git-pull-all goes to Kyle Purkiss!
# Kyle.Purkiss@Blackline.com

function git-pull-all {
   $CurDir = pwd
   Get-ChildItem -Depth 1 -Directory | % {
       Push-Location $_
       write-host "Checking $($_.Name)" -ForegroundColor Green -BackgroundColor Black
       if (Test-Path .\.git) {
           git pull --all
       } else {
           write-host "$($_.Name) is not a git repo"
       }
       Pop-Location
   }
   sl $CurDir
}

function appool-reset { $env:SERVER = Read-Host -Prompt 'Input $Server Name'
#write-host $env:SERVER
invoke-command -cn $env:SERVER -script {
$inst = $args[0]
write-host $inst
import-module WebAdministration
$appPool = (Get-Item "IIS:\Sites\Default Web Site\$inst"| Select-Object applicationPool).applicationPool; Write-Host $appPool; Restart-WebItem IIS:\AppPools\$appPool
} -argumentList $env:INSTANCE
}


function Save-TinyUrlFile
{
    PARAM (
        $TinyUrl,
        $DestinationFolder
    )

    $response = Invoke-WebRequest -Uri $TinyUrl
    $filename = [System.IO.Path]::GetFileName($response.BaseResponse.ResponseUri.OriginalString)
    $filepath = [System.IO.Path]::Combine($DestinationFolder, $filename)
    try
    {
        $filestream = [System.IO.File]::Create($filepath)
        $response.RawContentStream.WriteTo($filestream)
        $filestream.Close()
    }
    finally
    {
        if ($filestream)
        {
            $filestream.Dispose();
        }
    }
}

# Add gitit code - use to quickly submit code with proper formatting
######################################################################
function gitit {
  write-host "Write Your Commit Message" -ForegroundColor Black -BackgroundColor White
  $comment = Read-Host 'Message:'
git add *;
git commit -m  $comment;
git push origin master
}

# Credit for info - myself. duh.
#####################################################################

[Cmdletbinding()] 
Param( 
    [string]$Computername = "$"
) 
cls 

Write-Host "Logged in User:"
whoami

$PysicalMemory = Get-WmiObject -class "win32_physicalmemory" -namespace "root\CIMV2" -ComputerName $Computername 
 
Write-Host "Memore Modules:" -ForegroundColor Green 
$PysicalMemory | Format-Table Tag,BankLabel,@{n="Capacity(GB)";e={$_.Capacity/1GB}},Manufacturer,PartNumber,Speed -AutoSize 
 
Write-Host "Total Memory:" -ForegroundColor Green 
Write-Host "$((($PysicalMemory).Capacity | Measure-Object -Sum).Sum/1GB)GB" 
 
$TotalSlots = ((Get-WmiObject -Class "win32_PhysicalMemoryArray" -namespace "root\CIMV2" -ComputerName $Computername).MemoryDevices | Measure-Object -Sum).Sum 
Write-Host "`nTotal Memory Slots:" -ForegroundColor Green 
Write-Host $TotalSlots 
 
$UsedSlots = (($PysicalMemory) | Measure-Object).Count  
Write-Host "`nUsed Memory Slots:" -ForegroundColor Green 
Write-Host $UsedSlots 
 
If($UsedSlots -eq $TotalSlots)
{ 
    Write-Host "All memory slots are in use. No available slots!" -ForegroundColor Yellow 
} 


# Load External Modules! #

#Tell Me This Profile Loaded Completely and Correctly#
New-Alias cowsay "$PSScriptRoot\lib\cowsay.ps1"
cls
cowsay -f tux "Jeremy's Custom Shell and Profile are Loaded!"
                # *** END OF PS PROFILE *** #
