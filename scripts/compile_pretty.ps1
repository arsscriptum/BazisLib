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
    [Alias('q')]
    [switch]$Quiet,
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
    Write-Host "`n𝓬𝓸𝓶𝓹𝓲𝓵𝓮.𝓮𝔁𝓮 - 𝓒𝓸𝓶𝓹𝓲𝓵𝓪𝓽𝓲𝓸𝓷 𝓣𝓸𝓸𝓵" -f Blue
    Write-Host "𝒞ℴ𝓅𝓎𝓇𝒾ℊ𝒽𝓉 (𝒞) 2000-2021 𝒢𝓊𝒾𝓁𝓁𝒶𝓊𝓂ℯ 𝒫𝓁𝒶𝓃𝓉ℯ`n" -f Gray
}
function Out-Usage{  # NOEXPORT
    Write-Host "𝓾𝓼𝓪𝓰𝓮: 𝓬𝓸𝓶𝓹𝓲𝓵𝓮.𝓮𝔁𝓮  [𝓾𝓻𝓵] <-𝓹 𝓭𝓮𝓼𝓽𝓲𝓷𝓪𝓽𝓲𝓸𝓷 𝓹𝓪𝓽𝓱> <-𝓶 𝓭𝓸𝔀𝓷𝓵𝓸𝓪𝓭 𝓶𝓸𝓭𝓮> <-𝓪>`n" -f Gray
    Write-Host "𝒯𝒽ℯ 𝒻ℴ𝓁𝓁ℴ𝓌𝒾𝓃ℊ 𝒸𝓂𝒹𝓁𝒾𝓃ℯ ℴ𝓅𝓉𝒾ℴ𝓃𝓈 𝒶𝓇ℯ 𝒶𝓋𝒶𝒾𝓁𝒶𝒷𝓁ℯ:" -f Gray
    Write-Host "`t-𝒽ℯ𝓁𝓅            𝓈𝒽ℴ𝓌 𝒽ℯ𝓁𝓅" -f Gray
    Write-Host "`t-ℒ𝒾𝒷𝒫𝒶𝓉𝒽         𝓈ℴ𝓊𝓇𝒸ℯ 𝓁ℴ𝒸𝒶𝓉𝒾ℴ𝓃 ℴ𝒻 𝓉𝒽ℯ 𝒻𝒾𝓁ℯ𝓈 𝓉𝒽𝒶𝓉 𝓎ℴ𝓊 𝓌𝒶𝓃𝓉 𝓉ℴ 𝓉𝓇𝒶𝓃𝓈𝒻ℯ𝓇" -f Gray
    Write-Host "`t-𝒟ℯ𝓅𝓁ℴ𝓎𝒫𝒶𝓉𝒽     𝒹ℯ𝓈𝓉𝒾𝓃𝒶𝓉𝒾ℴ𝓃 𝓁ℴ𝒸𝒶𝓉𝒾ℴ𝓃 ℴ𝒻 𝓉𝒽ℯ 𝒻𝒾𝓁ℯ𝓈 𝓉𝒽𝒶𝓉 𝓎ℴ𝓊 𝓌𝒶𝓃𝓉 𝓉ℴ 𝓉𝓇𝒶𝓃𝓈𝒻ℯ𝓇." -f Gray 
    Write-Host "`t-𝒫𝓁𝒶𝓉𝒻ℴ𝓇𝓂       𝒷𝓊𝒾𝓁𝒹 𝓅𝓁𝒶𝓉ℴ𝓇𝓂" -f Gray
}


function UpdateConsoleLine{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Message to be printed
        [Parameter(Mandatory = $True, Position = 0)] 
        [string] $Message,

        # Cursor position where message is to be printed
        [int] $Leftpos = -1,
        [int] $Toppos = -1,

        # Foreground and Background colors for the message
        [System.ConsoleColor] $ForegroundColor = [System.Console]::ForegroundColor,
        [System.ConsoleColor] $BackgroundColor = [System.Console]::BackgroundColor,
        
        # Clear whatever is typed on this line currently
        [switch] $ClearLine,

        # After printing the message, return the cursor back to its initial position.
        [switch] $StayOnSameLine
    ) 

       # Save the current positions. If StayOnSameLine switch is supplied, we should go back to these.
    $CurrCursorLeft = [System.Console]::get_CursorLeft()
    $CurrCursorTop = [System.Console]::get_CursorTop()
    $CurrForegroundColor = [System.Console]::ForegroundColor
    $CurrBackgroundColor = [System.Console]::BackgroundColor

    
    # Get the passed values of foreground and backgroun colors, and left and top cursor positions
    $NewForegroundColor = $ForegroundColor
    $NewBackgroundColor = $BackgroundColor

    if ($Leftpos -ge 0) {
        $NewCursorLeft = $Leftpos
    } else {
        $NewCursorLeft = $CurrCursorLeft
    }

    if ($Toppos -ge 0) {
        $NewCursorTop = $Toppos
    } else {
        $NewCursorTop = $CurrCursorTop
    }

    # if clearline switch is present, clear the current line on the console by writing " "
    if ( $ClearLine ) {                        
        $clearmsg = " " * ([System.Console]::WindowWidth - 1)  
        [System.Console]::SetCursorPosition(0, $NewCursorTop)
        [System.Console]::Write($clearmsg)            
    }

    # Update the console with the message.
    [System.Console]::ForegroundColor = $NewForegroundColor
    [System.Console]::BackgroundColor = $NewBackgroundColor    
    [System.Console]::SetCursorPosition($NewCursorLeft, $NewCursorTop)
    if ( $StayOnSameLine ) { 
        # Dont print newline at the end, set cursor back to original position
        [System.Console]::Write($Message)
        [System.Console]::SetCursorPosition($CurrCursorLeft, $CurrCursorTop)
    } else {
        [System.Console]::WriteLine($Message)
    }    

    # Set foreground and backgroun colors back to original values.
    [System.Console]::ForegroundColor = $CurrForegroundColor
    [System.Console]::BackgroundColor = $CurrBackgroundColor

}
[string]$Script:FullChar = "O"
[string]$Script:EmptyChar = "-"
$Script:Max = 40
$Script:Half = 20
$Script:Index = 0
$Script:stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$Script:EstimatedSeconds = 3


function ShowCoolProgressBar{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false,Position=0)][int]$DelayMs=100
    )
    $Script:Index++
    $Half = $Max/ 2
    if($Index -ge $Max){ 
        $Script:Pos=0
        $Script:Index=0
    }elseif($Index -ge $Half){ 
        $Script:Pos = $Max-$Index
    }else{
        $Script:Pos++
    }

    $str = ''
    For($a = 0 ; $a -lt $Script:Pos ; $a++){
        $str += "$Script:EmptyChar"
    }
    $str += "$Script:FullChar"
    For($a = $Half ; $a -gt $Script:Pos ; $a--){
        $str += "$Script:EmptyChar"
    }
    $ElapsedTimeStr = ''
    $ts =  [timespan]::fromseconds($Script:ElapsedSeconds)
    if($ts.Ticks -gt 0){
        $ElapsedTimeStr = "{0:mm:ss}" -f ([datetime]$ts.Ticks)
    }
    $ProgressMessage = "{0} {1}" -f $str, $ElapsedTimeStr
    UpdateConsoleLine "$ProgressMessage" -ForegroundColor "Gray"  -ClearLine -StayOnSameLine
    Start-Sleep -Milliseconds $DelayMs
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

$buildJob = {
    param([string]$msbuild,[string]$project,[string]$op,[string]$cfg)   
    
    &"$msbuild" "$project" "/t:$op" "/p:Configuration=$cfg" "/target:$op" "/p:platform=x64"
    
    Write-Output "$totalMs"
}


function StartBuild{
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true,Position=0)]
    [string]$project,
    [Parameter(Mandatory = $true,Position=1)]
    [string]$config
)
    $Script:stopwatch.Reset()
    $Script:stopwatch.Start()
     $basename = (gi $project).BaseName
     $JobName = "$basename-$op"
    $jobby = Start-Job -Name $JobName -ScriptBlock $buildJob -ArgumentList ($msbuild,$project,$op,$config)
    $Building  = $True
    [string]$rndstr = (New-Guid).Guid
    $rndstr=$rndstr.substring($rndstr.Length-4)
    $TmpProgressFile = "$ENV:Temp\$JobName_$rndstr.txt"

    if($Asynchronous){ 
        $Building  = $False
        Write-Host "Asynchronous Mode..."
        return
    }

    $e = "$([char]27)"
    #hide the cursor
    Write-Host "$e[?25l"  -NoNewline  
    $threshold = 30
    while($Building){

        $JobState = (Get-Job -Name $JobName).State
        Write-verbose "JobState: $JobState"

                             
        if($Quiet){ 
             $Script:ElapsedSeconds = $Script:EstimatedSeconds-$stopwatch.Elapsed.TotalSeconds
            ShowCoolProgressBar 100
            $threshold--

            if($threshold -lt 0){
                if($JobState -eq 'Completed'){ 
                    $Building = $False 
                } 
            }
            Receive-Job -Name $JobName *>> $TmpProgressFile
         
        }else{
             Receive-Job -Name $JobName *>> $TmpProgressFile
            $str = Get-Content $TmpProgressFile -Tail 1
            Write-Host "$str" -f DarkYellow
            Start-Sleep -Milliseconds 500
        }
            
    }                      
    
     #restore scrolling region
     Write-Host "$e[s$($e)[r$($e)[u" -NoNewline
    #show the cursor
    Write-Host "$e[?25h"   
           

    $totalMs = $stopwatch.Elapsed.TotalMilliseconds
    return $totalMs
}

function StartMsProcess([string]$cfg){
    $color = 'DarkRed'
    if($cfg -imatch 'Debug'){
        $color = 'DarkYellow'
    }
    Write-Host "ℬ𝓊𝒾𝓁𝒹𝒾𝓃ℊ 𝓅𝓇ℴ𝒿ℯ𝒸𝓉 𝒸ℴ𝓇ℯ" -f $color

    $totalMs =  StartBuild "$bzscore" "$cfg"
     $log =  "𝓬𝓸𝓶𝓹𝓵𝓮𝓽𝓮𝓭 𝓲𝓷 {0:f2} 𝓼𝓮𝓬𝓸𝓷𝓭𝓼" -f ($totalMs / 1000)
    Write-HOst -f Gray "$log"
    Write-Host "ℬ𝓊𝒾𝓁𝒹𝒾𝓃ℊ 𝓅𝓇ℴ𝒿ℯ𝒸𝓉 𝒽𝓁𝓅"  -f $color


    $totalMs =  StartBuild "$bzshlp" "$cfg"
    $log =  "𝓬𝓸𝓶𝓹𝓵𝓮𝓽𝓮𝓭 𝓲𝓷 {0:f2} 𝓼𝓮𝓬𝓸𝓷𝓭𝓼" -f ($totalMs / 1000)
    Write-HOst -f Gray "$log"

 
}





switch($Configuration.ToLower()){

    'all'       {

                    StartMsProcess('Debug')
                    StartMsProcess('Release')
                }

    'debug'     {
                    StartMsProcess('Debug')
                }
    'release'   {
                    StartMsProcess('Release')
                }
    default     {
                }


}



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
