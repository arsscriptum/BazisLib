<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   Write-LogEntry
#̷𝓍   
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
    [Alias('p')]
    [string]$LibPath,
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Destination Directory where the files are saved", Position=1)]
    [Alias('d')]
    [string]$DeployPath,
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Build platform", Position=2)]
    [ValidateSet('x64','x86')]
    [string]$Platform,
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Build configuration", Position=3)]
    [string]$Configuration,
    [Parameter(Mandatory=$false)]
    [Alias('h')]
    [switch]$Help    
)


$CurrentPath = (Get-Location).Path
$CmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = '$pid'" | select CommandLine ).CommandLine   
[string[]]$UserCommandArray = $CmdLine.Split(' ')
$ProgramFullPath = $UserCommandArray[0].Replace('"','')
$ProgramDirectory = (gi $ProgramFullPath).DirectoryName
$ProgramName = (gi $ProgramFullPath).Name
$ProgramBasename = (gi $ProgramFullPath).BaseName

$Global:LogFilePath = Join-Path ((Get-Location).Path) 'downloadtool.log'
Remove-Item $Global:LogFilePath -Force -ErrorAction Ignore | Out-Null
New-Item $Global:LogFilePath -Force -ItemType file -ErrorAction Ignore | Out-Null

if(($ProgramName -eq 'pwsh.exe') -Or ($ProgramName -eq 'powershell.exe')){
    $MODE_NATIVE = $False
    $MODE_SCRIPT = $True
}else{
    $MODE_NATIVE = $True
    $MODE_SCRIPT = $False
}


function Get-PossibleDirectoryName([string]$Path) {
    if([string]::IsNullOrEmpty($Path)){
        Show-MyPopup "ERROR" "PossibleDirectoryName Path error" 'Error' 
        return ""
    }
        if(Test-Path -Path $Path -PathType Container){
            $directory = $Path.Replace('/','\').Trim('\').Trim()
            return $directory
        }
        $resolvedPath = Resolve-Path -Path $Path -ErrorVariable resolvePathError -ErrorAction SilentlyContinue

        if ($null -eq $resolvedPath)
        {
            $fullpath = $resolvePathError[0].TargetObject
            [uri]$u = $fullpath
            $segcount = $u.Segments.Count
            $directory = ''
            for($x = 1 ; $x -lt $segcount-1 ; $x++){
                $directory += $u.Segments[$x].Replace('/','\')
                $directory = $directory.Trim()
            }
        
            return $directory
        }
        else
        {
            $fullpath = $resolvedPath.ProviderPath
            $directory = (Get-Item -Path $fullpath).DirectoryName
            $directory = $directory.Trim()
            return $directory
        }
    
}

Function Show-MyPopup{
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [String]$Title,
        [Parameter(Position=1,Mandatory=$True)]
        [String]$Message,
        [Parameter(Position=2,Mandatory=$False)]
        [ValidateSet('None','Hand','Error','Stop','Question','Exclamation','Warning','Asterisk','Information')]
        [String]$Icon="None",
        [Parameter(Position=3,Mandatory=$False)]
        [ValidateSet('OK', 'OKCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryCancel')]
        [String]$Type="OK",
        [ValidateSet('Button1','Button2','Button3')]
        [String]$DefaultButton="Button1",
        [ValidateSet('DefaultDesktopOnly', 'RightAlign', 'RtlReading', 'ServiceNotification')]
        [String]$Option="DefaultDesktopOnly"     

        
    )
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    return [Windows.Forms.MessageBox]::show($Message, $Title,$Type,$Icon,$DefaultButton,$Option)
}

function Out-Banner {  # NOEXPORT
    Write-Host "`n$ProgramBasename - Deploy Tool" -f Blue
    Write-Host "Copyright (C) 2000-2021 Guillaume Plante`n" -f Gray
}
function Out-Usage{  # NOEXPORT
    Write-Host "usage: $ProgramName  [url] <-p destination path> <-m download mode> <-a>`n" -f Gray
    Write-Host "The following cmdline options are available:" -f Gray
    Write-Host "`t-help            show help" -f Gray
    Write-Host "`t-LibPath         source location of the files that you want to transfer" -f Gray
    Write-Host "`t-DeployPath      destination location of the files that you want to transfer." -f Gray 
    Write-Host "`t-Platform        build platorm" -f Gray
    Write-Host "`t-Configuration   build configuration`n"  -f Gray
}


 Out-Banner

if($Help){
    Out-Usage
    return
}


$LibPath = (Resolve-Path "$LibPath" -ErrorAction Ignore).Path
$DeployPath = (Resolve-Path "$DeployPath" -ErrorAction Ignore).Path

Write-Host " LibPath       $LibPath"
Write-Host " DeployPath    $DeployPath"
Write-Host " Platform      $Platform"
Write-Host " Configuration $Configuration"

#Remove-Item -Path $DeployPath -Force -Recurse -ErrorAction Ignore | Out-Null
if(-not(Test-Path $DeployPath)){
     Write-Host " MakeDir      $DeployPath"
    New-Item -Path $DeployPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
}

(gci "$LibPath" -File) | %{
    $file = $_
    $FullName = $file.FullName
    $Name = $file.Name
    $Dest = Join-Path $DeployPath $Name
    Write-Host " WOULD COPY $FullName  ==> $Dest" -f Red

    #$Res = Copy-Item -Path $FullName -Destination $Dest -Force -PassThru
    #Write-Host "Copied file $($Res.Name). Size $($Res.Length) bytes."
}