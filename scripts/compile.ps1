<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   Write-LogEntry
#̷𝓍   
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug','Release','All')]
    [Alias('c')]
    [string]$Configuration="All",
    [Parameter(Mandatory=$false)]
    [Alias('r')]
    [switch]$Rebuild,
    [Parameter(Mandatory=$false)]
    [switch]$Clean,
    [Parameter(Mandatory=$false)]
    [Alias('a')]
    [switch]$Asynchronous,
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

$CurrentPath = (Get-Location).Path
$RootPath = (Resolve-Path "$CurrentPath\.." -ErrorAction Ignore).Path



#Remove-Item -Path $DeployPath -Force -Recurse -ErrorAction Ignore | Out-Null
#if(-not(Test-Path $DeployPath)){
     #Write-Host " MakeDir      $DeployPath"
    #New-Item -Path $DeployPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
#}

$bzshlp = Join-Path $RootPath 'bzshlp\bzshlp.vcxproj'
$bzscore = Join-Path $RootPath 'bzscore\bzscore.vcxproj'
$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe'
$op = 'Build'
if($Rebuild){
    $op = 'Rebuild'
}


Write-Host " RootPath $RootPath"
Write-Host " bzscore  $bzscore"
Write-Host " bzshlp   $bzshlp"

$buildJob = {
    param([string]$msbuild,[string]$project,[string]$op)   
    
    &"$msbuild" "$project" "/t:$op" "/p:Configuration=DEBUG" "/target:$op" "/p:platform=x64"
    
    Write-Output "$totalMs"
}


function StartBuild([string]$project){
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
     $basename = (gi $project).BaseName
     $JobName = "$basename-$op"
    $jobby = Start-Job -Name $JobName -ScriptBlock $buildJob -ArgumentList ($msbuild,$project,$op)
    $Building  = $True
    $TmpProgressFile = "$ENV:Temp\progress_$JobName.txt"

    if($Asynchronous){ 
        $Building  = $False
        Write-Host "Asynchronous Mode..."
        return
    }
    while($Building){

        $JobState = (Get-Job -Name $JobName).State
        Write-verbose "JobState: $JobState"
        if($JobState -eq 'Completed'){
            $Building = $False
        }
        Start-Sleep -Milliseconds 500
        Receive-Job -Name $JobName *>> $TmpProgressFile
                                   
        $str = Get-Content $TmpProgressFile -Tail 1
        Write-Host "$str" -f DarkYellow
    }                      
                                
    $Res = $jobby | Receive-Job -Wait
    $totalMs = $stopwatch.Elapsed.TotalMilliseconds
    return $totalMs
}


$totalMs = StartBuild($bzscore)
$log =  "compiled in {0:f2} seconds" -f ($totalMs / 1000)
Write-HOst -n -f DarkRed "[BZSCORE] " ; Write-HOst -f DarkGreen "$log"
$totalMs = StartBuild($bzshlp)
$log =  "compiled in {0:f2} seconds" -f ($totalMs / 1000)
Write-HOst -n -f DarkRed "[BZSHLP] " ; Write-HOst -f DarkGreen "$log"
<#
switch($Configuration.ToLower()){

    'all'       {
                    Write-Host "===================================================" -f DarkRed
                    Write-Host "                    BUILD bzscore                  " -f DarkCyan
                    Write-Host "===================================================" -f DarkRed
                    &"$msbuild" "$bzscore" "/t:$op" "/p:Configuration=DEBUG" "/target:Build" "/p:platform=x64"
                    &"$msbuild" "$bzshlp" "/t:$op" "/p:Configuration=RELEASE" "/target:Build" "/p:platform=x64"
                }

    'debug'     {
                    Write-Host "===================================================" -f DarkRed
                    Write-Host "                 BUILD bzscore DEBUG               " -f DarkCyan
                    Write-Host "===================================================" -f DarkRed
                    &"$msbuild" "$bzscore" "/t:$op" "/p:Configuration=DEBUG" "/target:Build" "/p:platform=x64"
                }
    'release'   {
                    Write-Host "===================================================" -f DarkRed
                    Write-Host "               BUILD bzscore RELEASE               " -f DarkCyan
                    Write-Host "===================================================" -f DarkRed
                    &"$msbuild" "$bzshlp" "/t:$op" "/p:Configuration=RELEASE" "/target:Build" "/p:platform=x64"
                }
    default     {
                    &"$msbuild" "$bzshlp" "/t:$op" "/p:Configuration=RELEASE" "/target:Build" "/p:platform=x64"
                }


}
#>


<#
(gci "$LibPath" -File) | %{
    $file = $_
    $FullName = $file.FullName
    $Name = $file.Name
    $Dest = Join-Path $DeployPath $Name
    Write-Host " WOULD COPY $FullName  ==> $Dest" -f Red

    #$Res = Copy-Item -Path $FullName -Destination $Dest -Force -PassThru
    #Write-Host "Copied file $($Res.Name). Size $($Res.Length) bytes."
}
#>
