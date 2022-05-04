#!/usr/bin/env -S pwsh -nop
#requires -version 5

# (!) This file must to be saved in UTF-8 with BOM encoding in order to work with legacy Powershell 5.x

<#PSScriptInfo
.VERSION 2.4.1
.GUID a9a07f39-87e7-4164-9395-27cb54d86656
.AUTHOR Kied Llaentenn and contributers
.PROJECTURI https://github.com/kiedtl/winfetch
.COMPANYNAME
.COPYRIGHT
.TAGS neofetch screenfetch system-info commandline
.LICENSEURI https://github.com/kiedtl/winfetch/blob/master/LICENSE
.ICONURI https://lptstr.github.io/lptstr-images/proj/winfetch/logo.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.SYNOPSIS
    Winfetch - Neofetch for Windows in PowerShell 5+
.DESCRIPTION
    Winfetch is a command-line system information utility for Windows written in PowerShell.
.PARAMETER image
    Display a pixelated image instead of the usual logo.
.PARAMETER ascii
    Display the image using ASCII characters instead of blocks.
.PARAMETER genconf
    Reset your configuration file to the default.
.PARAMETER configpath
    Specify a path to a custom config file.
.PARAMETER noimage
    Do not display any image or logo; display information only.
.PARAMETER logo
    Sets the version of Windows to derive the logo from.
.PARAMETER imgwidth
    Specify width for image/logo. Default is 35.
.PARAMETER blink
    Make the logo blink.
.PARAMETER stripansi
    Output without any text effects or colors.
.PARAMETER all
    Display all built-in info segments.
.PARAMETER help
    Display this help message.
.PARAMETER cpustyle
    Specify how to show information level for CPU usage
.PARAMETER memorystyle
    Specify how to show information level for RAM usage
.PARAMETER diskstyle
    Specify how to show information level for disks' usage
.PARAMETER batterystyle
    Specify how to show information level for battery
.PARAMETER showdisks
    Configure which disks are shown, use '-showdisks *' to show all.
.PARAMETER showpkgs
    Configure which package managers are shown, e.g. '-showpkgs winget,scoop,choco'.
.INPUTS
    System.String
.OUTPUTS
    System.String[]
.NOTES
    Run Winfetch without arguments to view core functionality.
#>
[CmdletBinding()]
param(
    [string][alias('i')]$image,
    [switch][alias('k')]$ascii,
    [switch][alias('g')]$genconf,
    [string][alias('c')]$configpath,
    [switch][alias('n')]$noimage,
    [string][alias('l')]$logo,
    [switch][alias('b')]$blink,
    [switch][alias('s')]$stripansi,
    [switch][alias('a')]$all,
    [switch][alias('h')]$help,
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$cpustyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$memorystyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$diskstyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$batterystyle = "text",
    [ValidateScript({$_ -gt 1 -and $_ -lt $Host.UI.RawUI.WindowSize.Width-1})][alias('w')][int]$imgwidth = 35,
    [array]$showdisks = @($env:SystemDrive),
    [array]$showpkgs = @("scoop", "choco")
)

if (-not ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5)) {
    Write-Error "Only supported on Windows."
    exit 1
}

# ===== DISPLAY HELP =====
if ($help) {
    if (Get-Command -Name less -ErrorAction Ignore) {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full | less
    } else {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full
    }
    exit 0
}


# ===== CONFIG MANAGEMENT =====
$defaultConfig = @'
# ===== WINFETCH CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Display image using ASCII characters
# $ascii = $true

# Set the version of Windows to derive the logo from.
# $logo = "Windows 10"

# Specify width for image/logo
# $imgwidth = 40

# Make the logo blink
# $blink = $true

# Display all built-in info segments.
# $all = $true

# Add a custom info line
# function info_custom_time {
#     return @{
#         title = "Time"
#         content = (Get-Date)
#     }
# }

# Configure which disks are shown
# $ShowDisks = @("C:", "D:")
# Show all available disks
# $ShowDisks = @("*")

# Configure which package managers are shown
# disabling unused ones will improve speed
# $ShowPkgs = @("winget", "scoop", "choco")

# Use the following option to specify custom package managers.
# Create a function with that name as suffix, and which returns
# the number of packages. Two examples are shown here:
# $CustomPkgs = @("cargo", "just-install")
# function info_pkg_cargo {
#     return (cargo install --list | Where-Object {$_ -like "*:" }).Length
# }
# function info_pkg_just-install {
#     return (just-install list).Length
# }

# Configure how to show info for levels
# Default is for text only.
# 'bar' is for bar only.
# 'textbar' is for text + bar.
# 'bartext' is for bar + text.
# $cpustyle = 'bar'
# $memorystyle = 'textbar'
# $diskstyle = 'bartext'
# $batterystyle = 'bartext'


# Remove the '#' from any of the lines in
# the following to **enable** their output.

@(
    "title"
    "dashes"
    "os"
    "computer"
    "kernel"
    "motherboard"
    # "custom_time"  # use custom info line
    "uptime"
    # "ps_pkgs"  # takes some time
    "pkgs"
    "pwsh"
    "resolution"
    "terminal"
    # "theme"
    "cpu"
    "gpu"
    # "cpu_usage"  # takes some time
    "memory"
    "disk"
    # "battery"
    # "locale"
    # "weather"
    # "local_ip"
    # "public_ip"
    "blank"
    "colorbar"
)

'@

if (-not $configPath) {
    if ($env:WINFETCH_CONFIG_PATH) {
        $configPath = $env:WINFETCH_CONFIG_PATH
    } else {
        $configPath = "${env:USERPROFILE}\.config\winfetch\config.ps1"
    }
}

# generate default config
if ($genconf -and (Test-Path $configPath)) {
    $choiceYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "overwrite your configuration with the default"
    $choiceNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "do nothing and exit"
    $result = $Host.UI.PromptForChoice("Resetting your config to default will overwrite it.",
        "Do you want to continue?", ($choiceYes, $choiceNo), 1)
    if ($result -eq 0) { Remove-Item -Path $configPath } else { exit 1 }
}

if (-not (Test-Path $configPath) -or [String]::IsNullOrWhiteSpace((Get-Content $configPath))) {
    New-Item -Type File -Path $configPath -Value $defaultConfig -Force | Out-Null
    if ($genconf) {
        Write-Host "Saved default config to '$configPath'."
        exit 0
    } else {
        Write-Host "Missing config: Saved default config to '$configPath'."
    }
}

# load config file
$config = . $configPath
if (-not $config -or $all) {
    $config = @(
        "title"
        "dashes"
        "os"
        "computer"
        "kernel"
        "motherboard"
        "uptime"
        "resolution"
        "ps_pkgs"
        "pkgs"
        "pwsh"
        "terminal"
        "theme"
        "cpu"
        "gpu"
        "cpu_usage"
        "memory"
        "disk"
        "battery"
        "locale"
        "weather"
        "local_ip"
        "public_ip"
        "blank"
        "colorbar"
    )
}

# prevent config from overriding specified parameters
foreach ($param in $PSBoundParameters.Keys) {
    Set-Variable $param $PSBoundParameters[$param]
}

# ===== VARIABLES =====
$e = [char]0x1B
$ansiRegex = '([\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?\u0007)|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-ntqry=><~])))'
$cimSession = New-CimSession
$os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption,OSArchitecture -CimSession $cimSession
$t = if ($blink) { "5" } else { "1" }
$COLUMNS = $imgwidth

# ===== UTILITY FUNCTIONS =====
function get_percent_bar {
    param ([Parameter(Mandatory)][ValidateRange(0, 100)][int]$percent)

    $x = [char]9632
    $bar = $null

    $bar += "$e[97m[ $e[0m"
    for ($i = 1; $i -le ($barValue = ([math]::round($percent / 10))); $i++) {
        if ($i -le 6) { $bar += "$e[32m$x$e[0m" }
        elseif ($i -le 8) { $bar += "$e[93m$x$e[0m" }
        else { $bar += "$e[91m$x$e[0m" }
    }
    for ($i = 1; $i -le (10 - $barValue); $i++) { $bar += "$e[97m-$e[0m" }
    $bar += "$e[97m ]$e[0m"

    return $bar
}

function get_level_info {
    param (
        [string]$barprefix,
        [string]$style,
        [int]$percentage,
        [string]$text,
        [switch]$altstyle
    )

    switch ($style) {
        'bar' { return "$barprefix$(get_percent_bar $percentage)" }
        'textbar' { return "$text $(get_percent_bar $percentage)" }
        'bartext' { return "$barprefix$(get_percent_bar $percentage) $text" }
        default { if ($altstyle) { return "$percentage% ($text)" } else { return "$text ($percentage%)" }}
    }
}

function truncate_line {
    param (
        [string]$text,
        [int]$maxLength
    )
    $length = ($text -replace $ansiRegex, "").Length
    if ($length -le $maxLength) {
        return $text
    }
    $truncateAmt = $length - $maxLength
    $trucatedOutput = ""
    $parts = $text -split $ansiRegex

    for ($i = $parts.Length - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if (-not $part.StartsWith([char]27) -and $truncateAmt -gt 0) {
            $num = if ($truncateAmt -gt $part.Length) {
                $part.Length
            } else {
                $truncateAmt
            }
            $truncateAmt -= $num
            $part = $part.Substring(0, $part.Length - $num)
        }
        $trucatedOutput = "$part$trucatedOutput"
    }

    return $trucatedOutput
}

# ===== IMAGE =====
$img = if (-not $noimage) {
    if ($image) {
        if ($image -eq 'wallpaper') {
            $image = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
        }

        Add-Type -AssemblyName 'System.Drawing'
        $OldImage = if (Test-Path $image -PathType Leaf) {
            [Drawing.Bitmap]::FromFile((Resolve-Path $image))
        } else {
            [Drawing.Bitmap]::FromStream((Invoke-WebRequest $image -UseBasicParsing).RawContentStream)
        }

        # Divide scaled height by 2.2 to compensate for ASCII characters being taller than they are wide
        [int]$ROWS = $OldImage.Height / $OldImage.Width * $COLUMNS / $(if ($ascii) { 2.2 } else { 1 })
        $Bitmap = New-Object System.Drawing.Bitmap @($OldImage, [Drawing.Size]"$COLUMNS,$ROWS")

        if ($ascii) {
            $chars = ' .,:;+iIH$@'
            for ($i = 0; $i -lt $Bitmap.Height; $i++) {
              $currline = ""
              for ($j = 0; $j -lt $Bitmap.Width; $j++) {
                $p = $Bitmap.GetPixel($j, $i)
                $currline += "$e[38;2;$($p.R);$($p.G);$($p.B)m$($chars[[math]::Floor($p.GetBrightness() * $chars.Length)])$e[0m"
              }
              $currline
            }
        } else {
            for ($i = 0; $i -lt $Bitmap.Height; $i += 2) {
                $currline = ""
                for ($j = 0; $j -lt $Bitmap.Width; $j++) {
                    $back = $Bitmap.GetPixel($j, $i)
                    if ($i -ge $Bitmap.Height - 1) {
                        $foreVT = ""
                    } else {
                        $fore = $Bitmap.GetPixel($j, $i + 1)
                        $foreVT = "$e[48;2;$($fore.R);$($fore.G);$($fore.B)m"
                    }
                    $backVT = "$e[38;2;$($back.R);$($back.G);$($back.B)m"
                    $currline += "$backVT$foreVT$([char]0x2580)$e[0m"
                }
                $currline
            }
        }

        $Bitmap.Dispose()
        $OldImage.Dispose()

    } else {
        if (-not $logo) {
            if ($os -Like "*Windows 11 *") {
                $logo = "Windows 11"
            } elseif ($os -Like "*Windows 10 *" -Or $os -Like "*Windows 8.1 *" -Or $os -Like "*Windows 8 *") {
                $logo = "Windows 10"
            } else {
                $logo = "Windows 7"
            }
        }

        if ($logo -eq "Windows 11") {
            $COLUMNS = 32
            @(
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34m                                 "
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
                "${e}[${t};34mlllllllllllllll   lllllllllllllll"
            )
        } elseif ($logo -eq "Windows 10" -Or $logo -eq "Windows 8.1" -Or $logo -eq "Windows 8") {
            $COLUMNS = 34
            @(
                "${e}[${t};34m                    ....,,:;+ccllll"
                "${e}[${t};34m      ...,,+:;  cllllllllllllllllll"
                "${e}[${t};34m,cclllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34m                                   "
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
                "${e}[${t};34m``'ccllllllllll  lllllllllllllllllll"
                "${e}[${t};34m      ``' \\*::  :ccllllllllllllllll"
                "${e}[${t};34m                       ````````''*::cll"
                "${e}[${t};34m                                 ````"
            )
        } elseif ($logo -eq "Windows 7" -Or $logo -eq "Windows Vista" -Or $logo -eq "Windows XP") {
            $COLUMNS = 35
            @(
                "${e}[${t};31m        ,.=:!!t3Z3z.,               "
                "${e}[${t};31m       :tt:::tt333EE3               "
                "${e}[${t};31m       Et:::ztt33EEE  ${e}[32m@Ee.,      ..,"
                "${e}[${t};31m      ;tt:::tt333EE7 ${e}[32m;EEEEEEttttt33#"
                "${e}[${t};31m     :Et:::zt333EEQ. ${e}[32mSEEEEEttttt33QL"
                "${e}[${t};31m     it::::tt333EEF ${e}[32m@EEEEEEttttt33F "
                "${e}[${t};31m    ;3=*^``````'*4EEV ${e}[32m:EEEEEEttttt33@. "
                "${e}[${t};34m    ,.=::::it=., ${e}[31m`` ${e}[32m@EEEEEEtttz33QF  "
                "${e}[${t};34m   ;::::::::zt33)   ${e}[32m'4EEEtttji3P*   "
                "${e}[${t};34m  :t::::::::tt33 ${e}[33m:Z3z..  ${e}[32m```` ${e}[33m,..g.   "
                "${e}[${t};34m  i::::::::zt33F ${e}[33mAEEEtttt::::ztF    "
                "${e}[${t};34m ;:::::::::t33V ${e}[33m;EEEttttt::::t3     "
                "${e}[${t};34m E::::::::zt33L ${e}[33m@EEEtttt::::z3F     "
                "${e}[${t};34m{3=*^``````'*4E3) ${e}[33m;EEEtttt:::::tZ``     "
                "${e}[${t};34m            `` ${e}[33m:EEEEtttt::::z7       "
                "${e}[${t};33m                'VEzjt:;;z>*``       "
            )
        } elseif ($logo -eq "Microsoft") {
            $COLUMNS = 13
            @(
                "${e}[${t};31m┌─────┐${e}[32m┌─────┐"
                "${e}[${t};31m│     │${e}[32m│     │"
                "${e}[${t};31m│     │${e}[32m│     │"
                "${e}[${t};31m└─────┘${e}[32m└─────┘"
                "${e}[${t};34m┌─────┐${e}[33m┌─────┐"
                "${e}[${t};34m│     │${e}[33m│     │"
                "${e}[${t};34m│     │${e}[33m│     │"
                "${e}[${t};34m└─────┘${e}[33m└─────┘"
            )
        } else {
            Write-Error 'The only version logos supported are Windows 11, Windows 10/8.1/8, Windows 7/Vista/XP and Microsoft.'
            exit 1
        }
    }
}


# ===== BLANK =====
function info_blank {
    return @{}
}


# ===== COLORBAR =====
function info_colorbar {
    return @(
        @{
            title   = ""
            content = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}{0}[0m') -f $e, '   '
        },
        @{
            title   = ""
            content = ('{0}[0;100m{1}{0}[0;101m{1}{0}[0;102m{1}{0}[0;103m{1}{0}[0;104m{1}{0}[0;105m{1}{0}[0;106m{1}{0}[0;107m{1}{0}[0m') -f $e, '   '
        }
    )
}


# ===== OS =====
function info_os {
    return @{
        title   = "OS"
        content = "$($os.Caption.TrimStart('Microsoft ')) [$($os.OSArchitecture)]"
    }
}


# ===== MOTHERBOARD =====
function info_motherboard {
    $motherboard = Get-CimInstance Win32_BaseBoard -CimSession $cimSession -Property Manufacturer,Product
    return @{
        title = "Motherboard"
        content = "{0} {1}" -f $motherboard.Manufacturer, $motherboard.Product
    }
}


# ===== TITLE =====
function info_title {
    return @{
        title   = ""
        content = "${e}[1;33m{0}${e}[0m@${e}[1;33m{1}${e}[0m" -f [System.Environment]::UserName,$env:COMPUTERNAME
    }
}


# ===== DASHES =====
function info_dashes {
    $length = [System.Environment]::UserName.Length + $env:COMPUTERNAME.Length + 1
    return @{
        title   = ""
        content = "-" * $length
    }
}


# ===== COMPUTER =====
function info_computer {
    $compsys = Get-CimInstance -ClassName Win32_ComputerSystem -Property Manufacturer,Model -CimSession $cimSession
    return @{
        title   = "Host"
        content = '{0} {1}' -f $compsys.Manufacturer, $compsys.Model
    }
}


# ===== KERNEL =====
function info_kernel {
    return @{
        title   = "Kernel"
        content = "$([System.Environment]::OSVersion.Version)"
    }
}


# ===== UPTIME =====
function info_uptime {
    @{
        title   = "Uptime"
        content = $(switch ((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem -Property LastBootUpTime -CimSession $cimSession).LastBootUpTime) {
            ({ $PSItem.Days -eq 1 }) { '1 day' }
            ({ $PSItem.Days -gt 1 }) { "$($PSItem.Days) days" }
            ({ $PSItem.Hours -eq 1 }) { '1 hour' }
            ({ $PSItem.Hours -gt 1 }) { "$($PSItem.Hours) hours" }
            ({ $PSItem.Minutes -eq 1 }) { '1 minute' }
            ({ $PSItem.Minutes -gt 1 }) { "$($PSItem.Minutes) minutes" }
        }) -join ' '
    }
}


# ===== RESOLUTION =====
function info_resolution {
    Add-Type -AssemblyName System.Windows.Forms
    $displays = foreach ($monitor in [System.Windows.Forms.Screen]::AllScreens) {
        "$($monitor.Bounds.Size.Width)x$($monitor.Bounds.Size.Height)"
    }

    return @{
        title   = "Resolution"
        content = $displays -join ', '
    }
}


# ===== TERMINAL =====
# this section works by getting the parent processes of the current powershell instance.
function info_terminal {
    $programs = 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash', 'fish', 'env', 'nu', 'elvish', 'csh', 'tcsh', 'python', 'xonsh'
    if ($PSVersionTable.PSEdition.ToString() -ne 'Core') {
        $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID" -Property ParentProcessId -CimSession $cimSession).ParentProcessId -ErrorAction Ignore
        for () {
            if ($parent.ProcessName -in $programs) {
                $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($parent.ID)" -Property ParentProcessId -CimSession $cimSession).ParentProcessId -ErrorAction Ignore
                continue
            }
            break
        }
    } else {
        $parent = (Get-Process -Id $PID).Parent
        for () {
            if ($parent.ProcessName -in $programs) {
                $parent = (Get-Process -Id $parent.ID).Parent
                continue
            }
            break
        }
    }

    $terminal = switch ($parent.ProcessName) {
        { $PSItem -in 'explorer', 'conhost' } { 'Windows Console' }
        'Console' { 'Console2/Z' }
        'ConEmuC64' { 'ConEmu' }
        'WindowsTerminal' { 'Windows Terminal' }
        'FluentTerminal.SystemTray' { 'Fluent Terminal' }
        'Code' { 'Visual Studio Code' }
        default { $PSItem }
    }

    if (-not $terminal) {
        $terminal = "$e[91m(Unknown)"
    }

    return @{
        title   = "Terminal"
        content = $terminal
    }
}


# ===== THEME =====
function info_theme {
    $themeinfo = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme, AppsUseLightTheme
    $systheme = if ($themeinfo.SystemUsesLightTheme) { "Light" } else { "Dark" }
    $apptheme = if ($themeinfo.AppsUseLightTheme) { "Light" } else { "Dark" }
    return @{
        title = "Theme"
        content = "System - $systheme, Apps - $apptheme"
    }
}


# ===== CPU/GPU =====
function info_cpu {
    return @{
        title   = "CPU"
        content = (Get-CimInstance -ClassName Win32_Processor -Property Name -CimSession $cimSession).Name
    }
}

function info_gpu {
    [System.Collections.ArrayList]$lines = @()
    #loop through Win32_VideoController
    foreach ($gpu in Get-CimInstance -ClassName Win32_VideoController -Property Name -CimSession $cimSession) {
        [void]$lines.Add(@{
            title   = "GPU"
            content = $gpu.Name
        })
    }
    return $lines
}


# ===== CPU USAGE =====
function info_cpu_usage {
    $loadpercent = (Get-CimInstance -ClassName Win32_Processor -Property LoadPercentage -CimSession $cimSession).LoadPercentage
    $proccount = (Get-Process).Count
    return @{
        title   = "CPU Usage"
        content = get_level_info "" $cpustyle $loadpercent "$proccount processes" -altstyle
    }
}


# ===== MEMORY =====
function info_memory {
    $m = Get-CimInstance -ClassName Win32_OperatingSystem -Property TotalVisibleMemorySize,FreePhysicalMemory -CimSession $cimSession
    $total = $m.TotalVisibleMemorySize / 1mb
    $used = ($m.TotalVisibleMemorySize - $m.FreePhysicalMemory) / 1mb
    $usage = [math]::floor(($used / $total * 100))
    return @{
        title   = "Memory"
        content = get_level_info "   " $memorystyle $usage "$($used.ToString("#.##")) GiB / $($total.ToString("#.##")) GiB"
    }
}


# ===== DISK USAGE =====
function info_disk {
    [System.Collections.ArrayList]$lines = @()
    Add-Type @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace WinAPI
{
    public class DiskMethods
    {
        [DllImport("Kernel32.dll", CharSet = CharSet.Unicode, EntryPoint = "GetLogicalDriveStringsW", SetLastError = true)]
        private static extern int NativeGetLogicalDriveStringsW(
            int nBufferLength,
            char[] lpBuffer);

        // Wrapper around the native function for error handling
        public static char[] GetLogicalDriveStringsW()
        {
            int length = NativeGetLogicalDriveStringsW(0, null);
            if (length == 0)
                throw new Win32Exception();

            char[] buffer = new char[length];
            length = NativeGetLogicalDriveStringsW(length, buffer);
            if (length == 0)
                throw new Win32Exception();

            return buffer;
        }

        [DllImport("Kernel32.dll", SetLastError = true)]
        public static extern bool GetDiskFreeSpaceEx(
            string lpDirectoryName,
            out ulong lpFreeBytesAvailable,
            out ulong lpTotalNumberOfBytes,
            out ulong lpTotalNumberOfFreeBytes);
    }
}
'@

    function to_units($value) {
        if ($value -gt 1tb) {
            return "$([math]::round($value / 1tb, 1)) TiB"
        } else {
            return "$([math]::floor($value / 1gb)) GiB"
        }
    }

    # Convert System.String[] to System.Object[]
    $rawDiskLetters = [WinAPI.DiskMethods]::GetLogicalDriveStringsW()
    $allDiskLetters = @()
    foreach ($entry in $rawDiskLetters) {
        if ($entry -ne ":" -and $entry -ne "\" -and $entry + ":" -ne ":") {
            $allDiskLetters += $entry + ":"
        }
    }

    # Verification stage
    $diskLetters = @()
    foreach ($diskLetter in $allDiskLetters) {
        foreach ($showDiskLetter in $showDisks) {
            if ($diskLetter -eq $showDiskLetter -or $showDiskLetter -eq "*") {
                $diskLetters += $diskLetter
            }
        }
    }

    foreach ($diskLetter in $diskLetters) {
        $lpFreeBytesAvailable = 0
        $lpTotalNumberOfBytes = 0
        $lpTotalNumberOfFreeBytes = 0
        $success = [WinAPI.DiskMethods]::GetDiskFreeSpaceEx($diskLetter, [ref] $lpFreeBytesAvailable, [ref] $lpTotalNumberOfBytes, [ref] $lpTotalNumberOfFreeBytes)
        $total = $lpTotalNumberOfBytes
        $used = $total - $lpTotalNumberOfFreeBytes

        if (-not $success) {
            [void]$lines.Add(@{
                title   = "Disk ($diskLetter)"
                content = "(failed to get disk usage)"
            })
        }

        if ($total -gt 0) {
            $usage = [math]::floor(($used / $total * 100))
            [void]$lines.Add(@{
                title   = "Disk ($diskLetter)"
                content = get_level_info "" $diskstyle $usage "$(to_units $used) / $(to_units $total)"
            })
        }
    }

    return $lines
}


# ===== POWERSHELL VERSION =====
function info_pwsh {
    return @{
        title   = "Shell"
        content = "PowerShell v$($PSVersionTable.PSVersion)"
    }
}


# ===== POWERSHELL PACKAGES =====
function info_ps_pkgs {
    $ps_pkgs = @()

    $modulecount = (Get-InstalledModule).Length
    $scriptcount = (Get-InstalledScript).Length

    if ($modulecount) {
        if ($modulecount -eq 1) { $modulestring = "1 Module" }
        else { $modulestring = "$modulecount Modules" }

        $ps_pkgs += "$modulestring"
    }

    if ($scriptcount) {
        if ($scriptcount -eq 1) { $scriptstring = "1 Script" }
        else { $scriptstring = "$scriptcount Scripts" }

        $ps_pkgs += "$scriptstring"
    }

    if (-not $ps_pkgs) {
        $ps_pkgs = "(none)"
    }

    return @{
        title   = "PS Packages"
        content = $ps_pkgs -join ', '
    }
}


# ===== PACKAGES =====
function info_pkgs {
    $pkgs = @()

    if ("winget" -in $ShowPkgs -and (Get-Command -Name winget -ErrorAction Ignore)) {
        $wingetpkg = (winget list | Where-Object {$_.Trim("`n`r`t`b-\|/ ").Length -ne 0} | Measure-Object).Count - 1

        if ($wingetpkg) {
            $pkgs += "$wingetpkg (system)"
        }
    }

    if ("choco" -in $ShowPkgs -and (Get-Command -Name choco -ErrorAction Ignore)) {
        $chocopkg = (& clist -l)[-1].Split(' ')[0] - 1

        if ($chocopkg) {
            $pkgs += "$chocopkg (choco)"
        }
    }

    if ("scoop" -in $ShowPkgs) {
        $scoopdir = if ($Env:SCOOP) { "$Env:SCOOP\apps" } else { "$Env:UserProfile\scoop\apps" }

        if (Test-Path $scoopdir) {
            $scooppkg = (Get-ChildItem -Path $scoopdir -Directory).Count - 1
        }

        if ($scooppkg) {
            $pkgs += "$scooppkg (scoop)"
        }
    }

    foreach ($pkgitem in $CustomPkgs) {
        if (Test-Path Function:"info_pkg_$pkgitem") {
            $count = & "info_pkg_$pkgitem"
            $pkgs += "$count ($pkgitem)"
        }
    }

    if (-not $pkgs) {
        $pkgs = "(none)"
    }

    return @{
        title   = "Packages"
        content = $pkgs -join ', '
    }
}


# ===== BATTERY =====
function info_battery {
    Add-Type -AssemblyName System.Windows.Forms
    $battery = [System.Windows.Forms.SystemInformation]::PowerStatus

    if ($battery.BatteryChargeStatus -eq 'NoSystemBattery') {
        return @{
            title = "Battery"
            content = "(none)"
        }
    }

    $status = if ($battery.BatteryChargeStatus -like '*Charging*') {
        "Charging"
    } elseif ($battery.PowerLineStatus -like '*Online*') {
        "Plugged in"
    } else {
        "Discharging"
    }

    $timeRemaining = $battery.BatteryLifeRemaining / 60
    # Don't show time remaining if Windows hasn't properly reported it yet
    $timeFormatted = if ($timeRemaining -ge 0) {
        $hours = [math]::floor($timeRemaining / 60)
        $minutes = [math]::floor($timeRemaining % 60)
        ", ${hours}h ${minutes}m"
    }

    return @{
        title = "Battery"
        content = get_level_info "  " $batterystyle "$([math]::round($battery.BatteryLifePercent * 100))" "$status$timeFormatted" -altstyle
    }
}


# ===== LOCALE =====
function info_locale {
    # `Get-WinUserLanguageList` has a regression bug on PowerShell Core
    # https://github.com/PowerShell/PowerShellModuleCoverage/issues/18
    # A slight increase in response time is incurred as a result

    $contentstring = $null
    if ($PSVersionTable.PSVersion.Major -gt 5) {
        Import-Module International -UseWindowsPowerShell -WarningAction SilentlyContinue
        $contentstring = "$((Get-WinHomeLocation).HomeLocation) - $((Get-WinUserLanguageList)[0].LocalizedName)"
        Remove-Module International
    } else {
        $contentstring = "$((Get-WinHomeLocation).HomeLocation) - $((Get-WinUserLanguageList)[0].LocalizedName)"
    }

    return @{
        title = "Locale"
        content = $contentstring
    }
}


# ===== WEATHER =====
function info_weather {
    return @{
        title = "Weather"
        content = try {
            (Invoke-RestMethod wttr.in/?format="%t+-+%C+(%l)").TrimStart("+")
        } catch {
            "$e[91m(Network Error)"
        }
    }
}


# ===== IP =====
function info_local_ip {
    try {
        $indexDefault = Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object -Property RouteMetric | Select-Object -First 1 | Select-Object -ExpandProperty ifIndex
        $local_ip = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $indexDefault | Select-Object -ExpandProperty IPAddress
    } catch {
    }
    return @{
        title = "Local IP"
        content = if (-not $local_ip) {
            "$e[91m(Unknown)"
        } else {
            $local_ip
        }
    }
}

function info_public_ip {
    return @{
        title = "Public IP"
        content = try {
            Invoke-RestMethod ifconfig.me/ip
        } catch {
            "$e[91m(Network Error)"
        }
    }
}


if (-not $stripansi) {
    # unhide the cursor after a terminating error
    trap { "$e[?25h"; break }

    # reset terminal sequences and display a newline
    Write-Output "$e[0m$e[?25l"
} else {
    Write-Output ""
}

# write logo
if (-not $stripansi) {
    foreach ($line in $img) {
        Write-Output " $line"
    }
}

$GAP = 3
$writtenLines = 0
$freeSpace = $Host.UI.RawUI.WindowSize.Width - 1

# move cursor to top of image and to its right
if ($img -and -not $stripansi) {
    $freeSpace -= 1 + $COLUMNS + $GAP
    Write-Output "$e[$($img.Length + 1)A"
}


# write info
foreach ($item in $config) {
    if (Test-Path Function:"info_$item") {
        $info = & "info_$item"
    } else {
        $info = @{ title = "$e[31mfunction 'info_$item' not found" }
    }

    if (-not $info) {
        continue
    }

    if ($info -isnot [array]) {
        $info = @($info)
    }

    foreach ($line in $info) {
        $output = "$e[1;33m$($line["title"])$e[0m"

        if ($line["title"] -and $line["content"]) {
            $output += ": "
        }

        $output += "$($line["content"])"

        if ($img) {
            if (-not $stripansi) {
                # move cursor to right of image
                $output = "$e[$(2 + $COLUMNS + $GAP)G$output"
            } else {
                # write image progressively
                $imgline = ("$($img[$writtenLines])"  -replace $ansiRegex, "").PadRight($COLUMNS)
                $output = " $imgline   $output"
            }
        }

        $writtenLines++

        if ($stripansi) {
            $output = $output -replace $ansiRegex, ""
            if ($output.Length -gt $freeSpace) {
                $output = $output.Substring(0, $output.Length - ($output.Length - $freeSpace))
            }
        } else {
            $output = truncate_line $output $freeSpace
        }

        Write-Output $output
    }
}

if ($stripansi) {
    # write out remaining image lines
    for ($i = $writtenLines; $i -lt $img.Length; $i++) {
        $imgline = ("$($img[$i])"  -replace $ansiRegex, "").PadRight($COLUMNS)
        Write-Output " $imgline"
    }
}

# move cursor back to the bottom and print 2 newlines
if (-not $stripansi) {
    $diff = $img.Length - $writtenLines
    if ($img -and $diff -gt 0) {
        Write-Output "$e[${diff}B"
    } else {
        Write-Output ""
    }
    Write-Output "$e[?25h"
} else {
    Write-Output "`n"
}

#  ___ ___  ___
# | __/ _ \| __|
# | _| (_) | _|
# |___\___/|_|
#
