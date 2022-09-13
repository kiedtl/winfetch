﻿#!/usr/bin/env -S pwsh -nop
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
# $imgwidth = 24

# Custom ASCII Art
# This should be an array of strings, with positive
# height and width equal to $imgwidth defined above.
# $CustomAscii = @(
#     "⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣦⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣶⣾⣷⣶⣆⠸⣿⣿⡟⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣷⡈⠻⠿⠟⠻⠿⢿⣷⣤⣤⣄⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣦⠀ ⠀"
#     "⠀⠀⠀⢀⣤⣤⡘⢿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⡇ ⠀"
#     "⠀⠀⠀⣿⣿⣿⡇⢸⣿⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⣉⣉⡁ ⠀"
#     "⠀⠀⠀⠈⠛⠛⢡⣾⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⡇ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⠟⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⡿⢁⣴⣶⣦⣴⣶⣾⡿⠛⠛⠋⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠿⠿⢿⡿⠿⠏⢰⣿⣿⣧⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⠟⠀⠀ ⠀"
# )

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

    } elseif (($CustomAscii -is [Array]) -and ($CustomAscii.Length -gt 0)) {
        $CustomAscii
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
        } elseif ($logo -eq "Windows 2000" -Or $logo -eq "Windows 98" -Or $logo -eq "Windows 95") {
            $COLUMNS = 45
            @(
                "                         ${e}[${t};30mdBBBBBBBb"
                "                     ${e}[${t};30mdBBBBBBBBBBBBBBBb"
                "             ${e}[${t};30m   000 BBBBBBBBBBBBBBBBBBBB"
                "${e}[${t};30m:::::        000000 BBBBB${e}[${t};31mdBB${e}[${t};30mBBBB${e}[${t};32mBBBb${e}[${t};30mBBBBBBB"
                "${e}[${t};31m::::: ${e}[${t};30m====== 000${e}[${t};31m000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== ${e}[${t};31m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== ${e}[${t};31m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== ${e}[${t};31m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};32mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};31m::::: ====== 000000 BBBBf${e}[${t};30mBBBBBBBBBBB${e}[${t};32m`BBBB${e}[${t};30mBBBB"
                "${e}[${t};30m::::: ${e}[${t};31m====== 000${e}[${t};30m000 BBBBBBBBBBBBBBBBBBBBBBBBB"
                "${e}[${t};30m::::: ====== 000000 BBBBB${e}[${t};34mdBB${e}[${t};30mBBBB${e}[${t};33mBBBb${e}[${t};30mBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ${e}[${t};30m====== 000${e}[${t};34m000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};33mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};34m::::: ====== 000000 BBBBf${e}[${t};30mBBBBBBBBBBB${e}[${t};33m`BBBB${e}[${t};30mBBBB"
                "${e}[${t};30m::::: ${e}[${t};34m====== 000${e}[${t};30m000 BBBBBf         `BBBBBBBBB"
                "${e}[${t};30m   :: ====== 000000 BBf                `BBBBB"
                "     ${c1}   ==  000000 B                     BBB"
            )
        } else {
            Write-Error 'The only version logos supported are Windows 11, Windows 10/8.1/8, Windows 7/Vista/XP, Windows 2000/98/95 and Microsoft.'
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
    $cpu = Get-CimInstance -ClassName Win32_Processor -Property Name,MaxClockSpeed -CimSession $cimSession
    $cpuname = if ($cpu.Name.Contains('@')) {
        ($cpu.Name -Split ' @ ')[0].Trim()
    } else {
        $cpu.Name.Trim()
    }
    $cpufreq = [math]::round((([int]$cpu.MaxClockSpeed)/1000), 2)
    return @{
        title   = "CPU"
        content = "${cpuname} @ ${cpufreq}GHz"
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
    # Hashtables for language and region codes
    $localeLookup = @{
        "2" = "Antigua and Barbuda"
        "3" = "Afghanistan"
        "4" = "Algeria"
        "5" = "Azerbaijan"
        "6" = "Albania"
        "7" = "Armenia"
        "8" = "Andorra"
        "9" = "Angola"
        "10" = "American Samoa"
        "11" = "Argentina"
        "12" = "Australia"
        "14" = "Austria"
        "17" = "Bahrain"
        "18" = "Barbados"
        "19" = "Botswana"
        "20" = "Bermuda"
        "21" = "Belgium"
        "22" = "Bahamas"
        "23" = "Bangladesh"
        "24" = "Belize"
        "25" = "Bosnia and Herzegovina"
        "26" = "Bolivia"
        "27" = "Myanmar"
        "28" = "Benin"
        "29" = "Belarus"
        "30" = "Solomon Islands"
        "32" = "Brazil"
        "34" = "Bhutan"
        "35" = "Bulgaria"
        "37" = "Brunei"
        "38" = "Burundi"
        "39" = "Canada"
        "40" = "Cambodia"
        "41" = "Chad"
        "42" = "Sri Lanka"
        "43" = "Congo"
        "44" = "Congo (DRC)"
        "45" = "China"
        "46" = "Chile"
        "49" = "Cameroon"
        "50" = "Comoros"
        "51" = "Colombia"
        "54" = "Costa Rica"
        "55" = "Central African Republic"
        "56" = "Cuba"
        "57" = "Cabo Verde"
        "59" = "Cyprus"
        "61" = "Denmark"
        "62" = "Djibouti"
        "63" = "Dominica"
        "65" = "Dominican Republic"
        "66" = "Ecuador"
        "67" = "Egypt"
        "68" = "Ireland"
        "69" = "Equatorial Guinea"
        "70" = "Estonia"
        "71" = "Eritrea"
        "72" = "El Salvador"
        "73" = "Ethiopia"
        "75" = "Czech Republic"
        "77" = "Finland"
        "78" = "Fiji"
        "80" = "Micronesia"
        "81" = "Faroe Islands"
        "84" = "France"
        "86" = "Gambia"
        "87" = "Gabon"
        "88" = "Georgia"
        "89" = "Ghana"
        "90" = "Gibraltar"
        "91" = "Grenada"
        "93" = "Greenland"
        "94" = "Germany"
        "98" = "Greece"
        "99" = "Guatemala"
        "100" = "Guinea"
        "101" = "Guyana"
        "103" = "Haiti"
        "104" = "Hong Kong SAR"
        "106" = "Honduras"
        "108" = "Croatia"
        "109" = "Hungary"
        "110" = "Iceland"
        "111" = "Indonesia"
        "113" = "India"
        "114" = "British Indian Ocean Territory"
        "116" = "Iran"
        "117" = "Israel"
        "118" = "Italy"
        "119" = "Côte d'Ivoire"
        "121" = "Iraq"
        "122" = "Japan"
        "124" = "Jamaica"
        "125" = "Jan Mayen"
        "126" = "Jordan"
        "127" = "Johnston Atoll"
        "129" = "Kenya"
        "130" = "Kyrgyzstan"
        "131" = "North Korea"
        "133" = "Kiribati"
        "134" = "Korea"
        "136" = "Kuwait"
        "137" = "Kazakhstan"
        "138" = "Laos"
        "139" = "Lebanon"
        "140" = "Latvia"
        "141" = "Lithuania"
        "142" = "Liberia"
        "143" = "Slovakia"
        "145" = "Liechtenstein"
        "146" = "Lesotho"
        "147" = "Luxembourg"
        "148" = "Libya"
        "149" = "Madagascar"
        "151" = "Macao SAR"
        "152" = "Moldova"
        "154" = "Mongolia"
        "156" = "Malawi"
        "157" = "Mali"
        "158" = "Monaco"
        "159" = "Morocco"
        "160" = "Mauritius"
        "162" = "Mauritania"
        "163" = "Malta"
        "164" = "Oman"
        "165" = "Maldives"
        "166" = "Mexico"
        "167" = "Malaysia"
        "168" = "Mozambique"
        "173" = "Niger"
        "174" = "Vanuatu"
        "175" = "Nigeria"
        "176" = "Netherlands"
        "177" = "Norway"
        "178" = "Nepal"
        "180" = "Nauru"
        "181" = "Suriname"
        "182" = "Nicaragua"
        "183" = "New Zealand"
        "184" = "Palestinian Authority"
        "185" = "Paraguay"
        "187" = "Peru"
        "190" = "Pakistan"
        "191" = "Poland"
        "192" = "Panama"
        "193" = "Portugal"
        "194" = "Papua New Guinea"
        "195" = "Palau"
        "196" = "Guinea-Bissau"
        "197" = "Qatar"
        "198" = "Réunion"
        "199" = "Marshall Islands"
        "200" = "Romania"
        "201" = "Philippines"
        "202" = "Puerto Rico"
        "203" = "Russia"
        "204" = "Rwanda"
        "205" = "Saudi Arabia"
        "206" = "Saint Pierre and Miquelon"
        "207" = "Saint Kitts and Nevis"
        "208" = "Seychelles"
        "209" = "South Africa"
        "210" = "Senegal"
        "212" = "Slovenia"
        "213" = "Sierra Leone"
        "214" = "San Marino"
        "215" = "Singapore"
        "216" = "Somalia"
        "217" = "Spain"
        "218" = "Saint Lucia"
        "219" = "Sudan"
        "220" = "Svalbard"
        "221" = "Sweden"
        "222" = "Syria"
        "223" = "Switzerland"
        "224" = "United Arab Emirates"
        "225" = "Trinidad and Tobago"
        "227" = "Thailand"
        "228" = "Tajikistan"
        "231" = "Tonga"
        "232" = "Togo"
        "233" = "São Tomé and Príncipe"
        "234" = "Tunisia"
        "235" = "Turkey"
        "236" = "Tuvalu"
        "237" = "Taiwan"
        "238" = "Turkmenistan"
        "239" = "Tanzania"
        "240" = "Uganda"
        "241" = "Ukraine"
        "242" = "United Kingdom"
        "244" = "United States"
        "245" = "Burkina Faso"
        "246" = "Uruguay"
        "247" = "Uzbekistan"
        "248" = "Saint Vincent and the Grenadines"
        "249" = "Venezuela"
        "251" = "Vietnam"
        "252" = "U.S. Virgin Islands"
        "253" = "Vatican City"
        "254" = "Namibia"
        "258" = "Wake Island"
        "259" = "Samoa"
        "260" = "Swaziland"
        "261" = "Yemen"
        "263" = "Zambia"
        "264" = "Zimbabwe"
        "269" = "Serbia and Montenegro (Former)"
        "270" = "Montenegro"
        "271" = "Serbia"
        "273" = "Curaçao"
        "300" = "Anguilla"
        "276" = "South Sudan"
        "301" = "Antarctica"
        "302" = "Aruba"
        "303" = "Ascension Island"
        "304" = "Ashmore and Cartier Islands"
        "305" = "Baker Island"
        "306" = "Bouvet Island"
        "307" = "Cayman Islands"
        "308" = "Channel Islands"
        "309" = "Christmas Island"
        "310" = "Clipperton Island"
        "311" = "Cocos (Keeling) Islands"
        "312" = "Cook Islands"
        "313" = "Coral Sea Islands"
        "314" = "Diego Garcia"
        "315" = "Falkland Islands"
        "317" = "French Guiana"
        "318" = "French Polynesia"
        "319" = "French Southern Territories"
        "321" = "Guadeloupe"
        "322" = "Guam"
        "323" = "Guantanamo Bay"
        "324" = "Guernsey"
        "325" = "Heard Island and McDonald Islands"
        "326" = "Howland Island"
        "327" = "Jarvis Island"
        "328" = "Jersey"
        "329" = "Kingman Reef"
        "330" = "Martinique"
        "331" = "Mayotte"
        "332" = "Montserrat"
        "333" = "Netherlands Antilles (Former)"
        "334" = "New Caledonia"
        "335" = "Niue"
        "336" = "Norfolk Island"
        "337" = "Northern Mariana Islands"
        "338" = "Palmyra Atoll"
        "339" = "Pitcairn Islands"
        "340" = "Rota Island"
        "341" = "Saipan"
        "342" = "South Georgia and the South Sandwich Islands"
        "343" = "St Helena, Ascension and Tristan da Cunha"
        "346" = "Tinian Island"
        "347" = "Tokelau"
        "348" = "Tristan da Cunha"
        "349" = "Turks and Caicos Islands"
        "351" = "British Virgin Islands"
        "352" = "Wallis and Futuna"
        "742" = "Africa"
        "2129" = "Asia"
        "10541" = "Europe"
        "15126" = "Isle of Man"
        "19618" = "North Macedonia"
        "20900" = "Melanesia"
        "21206" = "Micronesia"
        "21242" = "Midway Islands"
        "23581" = "Northern America"
        "26286" = "Polynesia"
        "27082" = "Central America"
        "27114" = "Oceania"
        "30967" = "Sint Maarten"
        "31396" = "South America"
        "31706" = "Saint Martin"
        "39070" = "World"
        "42483" = "Western Africa"
        "42484" = "Middle Africa"
        "42487" = "Northern Africa"
        "47590" = "Central Asia"
        "47599" = "South-Eastern Asia"
        "47600" = "Eastern Asia"
        "47603" = "Eastern Africa"
        "47609" = "Eastern Europe"
        "47610" = "Southern Europe"
        "47611" = "Middle East"
        "47614" = "Southern Asia"
        "7299303" = "Timor-Leste"
        "9914689" = "Kosovo"
        "10026358" = "Americas"
        "10028789" = "Åland Islands"
        "10039880" = "Caribbean"
        "10039882" = "Northern Europe"
        "10039883" = "Southern Africa"
        "10210824" = "Western Europe"
        "10210825" = "Australia and New Zealand"
        "161832015" = "Saint Barthélemy"
        "161832256" = "U.S. Minor Outlying Islands"
        "161832257" = "Latin America and the Caribbean"
        "161832258" = "Bonaire, Sint Eustatius and Saba"
    }
    $languageLookup = @{
        "aa" = "Afar"
        "aa-DJ" = "Afar (Djibouti)"
        "aa-ER" = "Afar (Eritrea)"
        "aa-ET" = "Afar (Ethiopia)"
        "af" = "Afrikaans"
        "af-NA" = "Afrikaans (Namibia)"
        "af-ZA" = "Afrikaans (South Africa)"
        "agq" = "Aghem"
        "agq-CM" = "Aghem (Cameroon)"
        "ak" = "Akan"
        "ak-GH" = "Akan (Ghana)"
        "sq" = "Albanian"
        "sq-AL" = "Albanian (Albania)"
        "sq-XK" = "Albanian (Kosovo)"
        "sq-MK" = "Albanian (Macedonia, FYRO)"
        "gsw" = "Alsatian"
        "gsw-FR" = "Alsatian (France)"
        "gsw-LI" = "Alsatian (Liechtenstein)"
        "gsw-CH" = "Alsatian (Switzerland)"
        "am" = "Amharic"
        "am-ET" = "Amharic (Ethiopia)"
        "ar" = "Arabic"
        "ar-DZ" = "Arabic (Algeria)"
        "ar-BH" = "Arabic (Bahrain)"
        "ar-TD" = "Arabic (Chad)"
        "ar-KM" = "Arabic (Comoros)"
        "ar-DJ" = "Arabic (Djibouti)"
        "ar-EG" = "Arabic (Egypt)"
        "ar-ER" = "Arabic (Eritrea)"
        "ar-IQ" = "Arabic (Iraq)"
        "ar-IL" = "Arabic (Israel)"
        "ar-JO" = "Arabic (Jordan)"
        "ar-KW" = "Arabic (Kuwait)"
        "ar-LB" = "Arabic (Lebanon)"
        "ar-LY" = "Arabic (Libya)"
        "ar-MR" = "Arabic (Mauritania)"
        "ar-MA" = "Arabic (Morocco)"
        "ar-OM" = "Arabic (Oman)"
        "ar-PS" = "Arabic (Palestinian Authority)"
        "ar-QA" = "Arabic (Qatar)"
        "ar-SA" = "Arabic (Saudi Arabia)"
        "ar-SO" = "Arabic (Somalia)"
        "ar-SS" = "Arabic (South Sudan)"
        "ar-SD" = "Arabic (Sudan)"
        "ar-SY" = "Arabic (Syria)"
        "ar-TN" = "Arabic (Tunisia)"
        "ar-AE" = "Arabic (U.A.E.)"
        "ar-001" = "Arabic (World)"
        "ar-YE" = "Arabic (Yemen)"
        "hy" = "Armenian"
        "hy-AM" = "Armenian (Armenia)"
        "as" = "Assamese"
        "as-IN" = "Assamese (India)"
        "ast" = "Asturian"
        "ast-ES" = "Asturian (Spain)"
        "asa" = "Asu"
        "asa-TZ" = "Asu (Tanzania)"
        "az" = "Azerbaijani"
        "az-Cyrl" = "Azerbaijani (Cyrillic)"
        "az-Cyrl-AZ" = "Azerbaijani (Cyrillic, Azerbaijan)"
        "az-Latn" = "Azerbaijani (Latin)"
        "az-Latn-AZ" = "Azerbaijani (Latin, Azerbaijan)"
        "ksf" = "Bafia"
        "ksf-CM" = "Bafia (Cameroon)"
        "bm" = "Bambara"
        "bm-Latn" = "Bambara (Latin)"
        "bm-Latn-ML" = "Bambara (Latin, Mali)"
        "bn" = "Bangla"
        "bn-BD" = "Bangla (Bangladesh)"
        "bn-IN" = "Bangla (India)"
        "bas" = "Basaa"
        "bas-CM" = "Basaa (Cameroon)"
        "ba" = "Bashkir"
        "ba-RU" = "Bashkir (Russia)"
        "eu" = "Basque"
        "eu-ES" = "Basque (Basque)"
        "be" = "Belarusian"
        "be-BY" = "Belarusian (Belarus)"
        "bem" = "Bemba"
        "bem-ZM" = "Bemba (Zambia)"
        "bez" = "Bena"
        "bez-TZ" = "Bena (Tanzania)"
        "byn" = "Blin"
        "byn-ER" = "Blin (Eritrea)"
        "brx" = "Bodo"
        "brx-IN" = "Bodo (India)"
        "bs" = "Bosnian"
        "bs-Cyrl" = "Bosnian (Cyrillic)"
        "bs-Cyrl-BA" = "Bosnian (Cyrillic, Bosnia and Herzegovina)"
        "bs-Latn" = "Bosnian (Latin)"
        "bs-Latn-BA" = "Bosnian (Latin, Bosnia and Herzegovina)"
        "br" = "Breton"
        "br-FR" = "Breton (France)"
        "bg" = "Bulgarian"
        "bg-BG" = "Bulgarian (Bulgaria)"
        "my" = "Burmese"
        "my-MM" = "Burmese (Myanmar)"
        "ca" = "Catalan"
        "ca-AD" = "Catalan (Andorra)"
        "ca-ES" = "Catalan (Catalan)"
        "ca-FR" = "Catalan (France)"
        "ca-IT" = "Catalan (Italy)"
        "tzm-Arab" = "Central Atlas Tamazight (Arabic)"
        "tzm-Arab-MA" = "Central Atlas Tamazight (Arabic, Morocco)"
        "tzm-Latn-MA" = "Central Atlas Tamazight (Latin, Morocco)"
        "tzm-Tfng-MA" = "Central Atlas Tamazight (Tifinagh, Morocco)"
        "ku" = "Central Kurdish"
        "ku-Arab" = "Central Kurdish (Arabic)"
        "ku-Arab-IQ" = "Central Kurdish (Iraq)"
        "ce" = "Chechen"
        "ce-RU" = "Chechen (Russia)"
        "chr" = "Cherokee"
        "chr-Cher-US" = "Cherokee (Cherokee)"
        "chr-Cher" = "Cherokee (Cherokee)"
        "cgg" = "Chiga"
        "cgg-UG" = "Chiga (Uganda)"
        "zh" = "Chinese"
        "zh-Hans-HK" = "Chinese (Simplified Han, Hong Kong SAR)"
        "zh-Hans-MO" = "Chinese (Simplified Han, Macao SAR)"
        "zh-Hans" = "Chinese (Simplified)"
        "zh-CN" = "Chinese (Simplified, PRC)"
        "zh-SG" = "Chinese (Simplified, Singapore)"
        "zh-Hant" = "Chinese (Traditional)"
        "zh-HK" = "Chinese (Traditional, Hong Kong S.A.R.)"
        "zh-MO" = "Chinese (Traditional, Macao S.A.R.)"
        "zh-TW" = "Chinese (Traditional, Taiwan)"
        "cu" = "Church Slavic"
        "cu-RU" = "Church Slavic (Russia)"
        "ksh" = "Colognian"
        "kw" = "Cornish"
        "kw-GB" = "Cornish (United Kingdom)"
        "co" = "Corsican"
        "co-FR" = "Corsican (France)"
        "hr" = "Croatian"
        "hr-HR" = "Croatian (Croatia)"
        "hr-BA" = "Croatian (Latin, Bosnia and Herzegovina)"
        "cs" = "Czech"
        "cs-CZ" = "Czech (Czechia / Czech Republic)"
        "da" = "Danish"
        "da-DK" = "Danish (Denmark)"
        "da-GL" = "Danish (Greenland)"
        "prs" = "Dari"
        "prs-AF" = "Dari (Afghanistan)"
        "dv" = "Divehi"
        "dv-MV" = "Divehi (Maldives)"
        "dua" = "Duala"
        "dua-CM" = "Duala (Cameroon)"
        "nl" = "Dutch"
        "nl-AW" = "Dutch (Aruba)"
        "nl-BE" = "Dutch (Belgium)"
        "nl-BQ" = "Dutch (Bonaire, Sint Eustatius and Saba)"
        "nl-CW" = "Dutch (Curaçao)"
        "nl-NL" = "Dutch (Netherlands)"
        "nl-SX" = "Dutch (Sint Maarten)"
        "nl-SR" = "Dutch (Suriname)"
        "dz" = "Dzongkha"
        "dz-BT" = "Dzongkha (Bhutan)"
        "bin" = "Edo"
        "bin-NG" = "Edo (Nigeria)"
        "ebu" = "Embu"
        "ebu-KE" = "Embu (Kenya)"
        "en" = "English"
        "en-AS" = "English (American Samoa)"
        "en-AI" = "English (Anguilla)"
        "en-AG" = "English (Antigua and Barbuda)"
        "en-AU" = "English (Australia)"
        "en-AT" = "English (Austria)"
        "en-BS" = "English (Bahamas)"
        "en-BB" = "English (Barbados)"
        "en-BE" = "English (Belgium)"
        "en-BZ" = "English (Belize)"
        "en-BM" = "English (Bermuda)"
        "en-BW" = "English (Botswana)"
        "en-IO" = "English (British Indian Ocean Territory)"
        "en-VG" = "English (British Virgin Islands)"
        "en-BI" = "English (Burundi)"
        "en-CM" = "English (Cameroon)"
        "en-CA" = "English (Canada)"
        "en-029" = "English (Caribbean)"
        "en-KY" = "English (Cayman Islands)"
        "en-CX" = "English (Christmas Island)"
        "en-CC" = "English (Cocos [Keeling] Islands)"
        "en-CK" = "English (Cook Islands)"
        "en-CY" = "English (Cyprus)"
        "en-DK" = "English (Denmark)"
        "en-DM" = "English (Dominica)"
        "en-ER" = "English (Eritrea)"
        "en-150" = "English (Europe)"
        "en-FK" = "English (Falkland Islands)"
        "en-FJ" = "English (Fiji)"
        "en-FI" = "English (Finland)"
        "en-GM" = "English (Gambia)"
        "en-DE" = "English (Germany)"
        "en-GH" = "English (Ghana)"
        "en-GI" = "English (Gibraltar)"
        "en-GD" = "English (Grenada)"
        "en-GU" = "English (Guam)"
        "en-GG" = "English (Guernsey)"
        "en-GY" = "English (Guyana)"
        "en-HK" = "English (Hong Kong SAR)"
        "en-IN" = "English (India)"
        "en-ID" = "English (Indonesia)"
        "en-IE" = "English (Ireland)"
        "en-IM" = "English (Isle of Man)"
        "en-IL" = "English (Israel)"
        "en-JM" = "English (Jamaica)"
        "en-JE" = "English (Jersey)"
        "en-KE" = "English (Kenya)"
        "en-KI" = "English (Kiribati)"
        "en-LS" = "English (Lesotho)"
        "en-LR" = "English (Liberia)"
        "en-MO" = "English (Macao SAR)"
        "en-MG" = "English (Madagascar)"
        "en-MW" = "English (Malawi)"
        "en-MY" = "English (Malaysia)"
        "en-MT" = "English (Malta)"
        "en-MH" = "English (Marshall Islands)"
        "en-MU" = "English (Mauritius)"
        "en-FM" = "English (Micronesia)"
        "en-MS" = "English (Montserrat)"
        "en-NA" = "English (Namibia)"
        "en-NR" = "English (Nauru)"
        "en-NL" = "English (Netherlands)"
        "en-NZ" = "English (New Zealand)"
        "en-NG" = "English (Nigeria)"
        "en-NU" = "English (Niue)"
        "en-NF" = "English (Norfolk Island)"
        "en-MP" = "English (Northern Mariana Islands)"
        "en-PK" = "English (Pakistan)"
        "en-PW" = "English (Palau)"
        "en-PG" = "English (Papua New Guinea)"
        "en-PN" = "English (Pitcairn Islands)"
        "en-PR" = "English (Puerto Rico)"
        "en-PH" = "English (Philippines)"
        "en-RW" = "English (Rwanda)"
        "en-KN" = "English (Saint Kitts and Nevis)"
        "en-LC" = "English (Saint Lucia)"
        "en-VC" = "English (Saint Vincent and the Grenadines)"
        "en-WS" = "English (Samoa)"
        "en-SC" = "English (Seychelles)"
        "en-SL" = "English (Sierra Leone)"
        "en-SG" = "English (Singapore)"
        "en-SX" = "English (Sint Maarten)"
        "en-SI" = "English (Slovenia)"
        "en-SB" = "English (Solomon Islands)"
        "en-ZA" = "English (South Africa)"
        "en-SS" = "English (South Sudan)"
        "en-SH" = "English (St Helena, Ascension, Tristan da Cunha)"
        "en-SD" = "English (Sudan)"
        "en-SZ" = "English (Swaziland)"
        "en-SE" = "English (Sweden)"
        "en-CH" = "English (Switzerland)"
        "en-TZ" = "English (Tanzania)"
        "en-TK" = "English (Tokelau)"
        "en-TO" = "English (Tonga)"
        "en-TT" = "English (Trinidad and Tobago)"
        "en-TC" = "English (Turks and Caicos Islands)"
        "en-TV" = "English (Tuvalu)"
        "en-UG" = "English (Uganda)"
        "en-GB" = "English (United Kingdom)"
        "en-US" = "English (United States)"
        "en-UM" = "English (US Minor Outlying Islands)"
        "en-VI" = "English (US Virgin Islands)"
        "en-VU" = "English (Vanuatu)"
        "en-001" = "English (World)"
        "en-ZM" = "English (Zambia)"
        "en-ZW" = "English (Zimbabwe)"
        "eo" = "Esperanto"
        "eo-001" = "Esperanto (World)"
        "et" = "Estonian"
        "et-EE" = "Estonian (Estonia)"
        "ee" = "Ewe"
        "ee-GH" = "Ewe (Ghana)"
        "ee-TG" = "Ewe (Togo)"
        "ewo" = "Ewondo"
        "ewo-CM" = "Ewondo (Cameroon)"
        "fo" = "Faroese"
        "fo-DK" = "Faroese (Denmark)"
        "fo-FO" = "Faroese (Faroe Islands)"
        "fil" = "Filipino"
        "fil-PH" = "Filipino (Philippines)"
        "fi" = "Finnish"
        "fi-FI" = "Finnish (Finland)"
        "fr" = "French"
        "fr-DZ" = "French (Algeria)"
        "fr-BE" = "French (Belgium)"
        "fr-BJ" = "French (Benin)"
        "fr-BF" = "French (Burkina Faso)"
        "fr-BI" = "French (Burundi)"
        "fr-CM" = "French (Cameroon)"
        "fr-CA" = "French (Canada)"
        "fr-029" = "French (Caribbean)"
        "fr-CF" = "French (Central African Republic)"
        "fr-TD" = "French (Chad)"
        "fr-KM" = "French (Comoros)"
        "fr-CD" = "French (Congo DRC)"
        "fr-CG" = "French (Congo)"
        "fr-CI" = "French (Côte d’Ivoire)"
        "fr-DJ" = "French (Djibouti)"
        "fr-GQ" = "French (Equatorial Guinea)"
        "fr-FR" = "French (France)"
        "fr-GF" = "French (French Guiana)"
        "fr-PF" = "French (French Polynesia)"
        "fr-GA" = "French (Gabon)"
        "fr-GP" = "French (Guadeloupe)"
        "fr-GN" = "French (Guinea)"
        "fr-HT" = "French (Haiti)"
        "fr-LU" = "French (Luxembourg)"
        "fr-MG" = "French (Madagascar)"
        "fr-ML" = "French (Mali)"
        "fr-MQ" = "French (Martinique)"
        "fr-MR" = "French (Mauritania)"
        "fr-MU" = "French (Mauritius)"
        "fr-YT" = "French (Mayotte)"
        "fr-MC" = "French (Monaco)"
        "fr-MA" = "French (Morocco)"
        "fr-NC" = "French (New Caledonia)"
        "fr-NE" = "French (Niger)"
        "fr-RE" = "French (Reunion)"
        "fr-RW" = "French (Rwanda)"
        "fr-BL" = "French (Saint Barthélemy)"
        "fr-MF" = "French (Saint Martin)"
        "fr-PM" = "French (Saint Pierre and Miquelon)"
        "fr-SN" = "French (Senegal)"
        "fr-SC" = "French (Seychelles)"
        "fr-CH" = "French (Switzerland)"
        "fr-SY" = "French (Syria)"
        "fr-TG" = "French (Togo)"
        "fr-TN" = "French (Tunisia)"
        "fr-VU" = "French (Vanuatu)"
        "fr-WF" = "French (Wallis and Futuna)"
        "fy" = "Frisian"
        "fy-NL" = "Frisian (Netherlands)"
        "fur" = "Friulian"
        "fur-IT" = "Friulian (Italy)"
        "ff" = "Fulah"
        "ff-CM" = "Fulah (Cameroon)"
        "ff-GN" = "Fulah (Guinea)"
        "ff-Latn" = "Fulah (Latin)"
        "ff-Latn-SN" = "Fulah (Latin, Senegal)"
        "ff-MR" = "Fulah (Mauritania)"
        "ff-NG" = "Fulah (Nigeria)"
        "gl" = "Galician"
        "gl-ES" = "Galician (Galician)"
        "lg" = "Ganda"
        "lg-UG" = "Ganda (Uganda)"
        "ka" = "Georgian"
        "ka-GE" = "Georgian (Georgia)"
        "de" = "German"
        "de-AT" = "German (Austria)"
        "de-BE" = "German (Belgium)"
        "de-DE" = "German (Germany)"
        "de-IT" = "German (Italy)"
        "de-LI" = "German (Liechtenstein)"
        "de-LU" = "German (Luxembourg)"
        "de-CH" = "German (Switzerland)"
        "el" = "Greek"
        "el-CY" = "Greek (Cyprus)"
        "el-GR" = "Greek (Greece)"
        "kl" = "Greenlandic"
        "kl-GL" = "Greenlandic (Greenland)"
        "gn" = "Guarani"
        "gn-PY" = "Guarani (Paraguay)"
        "gu" = "Gujarati"
        "gu-IN" = "Gujarati (India)"
        "guz" = "Gusii"
        "guz-KE" = "Gusii (Kenya)"
        "ha" = "Hausa"
        "ha-Latn" = "Hausa (Latin)"
        "ha-Latn-GH" = "Hausa (Latin, Ghana)"
        "ha-Latn-NE" = "Hausa (Latin, Niger)"
        "ha-Latn-NG" = "Hausa (Latin, Nigeria)"
        "haw" = "Hawaiian"
        "haw-US" = "Hawaiian (United States)"
        "he" = "Hebrew"
        "he-IL" = "Hebrew (Israel)"
        "hi" = "Hindi"
        "hi-IN" = "Hindi (India)"
        "hu" = "Hungarian"
        "hu-HU" = "Hungarian (Hungary)"
        "ibb" = "Ibibio"
        "ibb-NG" = "Ibibio (Nigeria)"
        "is" = "Icelandic"
        "is-IS" = "Icelandic (Iceland)"
        "ig" = "Igbo"
        "ig-NG" = "Igbo (Nigeria)"
        "id" = "Indonesian"
        "id-ID" = "Indonesian (Indonesia)"
        "ia" = "Interlingua"
        "ia-FR" = "Interlingua (France)"
        "ia-001" = "Interlingua (World)"
        "iu" = "Inuktitut"
        "iu-Latn" = "Inuktitut (Latin)"
        "iu-Latn-CA" = "Inuktitut (Latin, Canada)"
        "iu-Cans" = "Inuktitut (Syllabics)"
        "iu-Cans-CA" = "Inuktitut (Syllabics, Canada)"
        ")" = "Invariant Language (Invariant Country"
        "ga" = "Irish"
        "ga-IE" = "Irish (Ireland)"
        "xh" = "isiXhosa"
        "xh-ZA" = "isiXhosa (South Africa)"
        "zu" = "isiZulu"
        "zu-ZA" = "isiZulu (South Africa)"
        "it" = "Italian"
        "it-IT" = "Italian (Italy)"
        "it-SM" = "Italian (San Marino)"
        "it-CH" = "Italian (Switzerland)"
        "it-VA" = "Italian (Vatican City)"
        "ja" = "Japanese"
        "ja-JP" = "Japanese (Japan)"
        "jv-Latn" = "Javanese"
        "jv" = "Javanese"
        "jv-Latn-ID" = "Javanese (Indonesia)"
        "jv-Java" = "Javanese (Javanese)"
        "jv-Java-ID" = "Javanese (Javanese, Indonesia)"
        "dyo" = "Jola-Fonyi"
        "dyo-SN" = "Jola-Fonyi (Senegal)"
        "kea" = "Kabuverdianu"
        "kea-CV" = "Kabuverdianu (Cabo Verde)"
        "kab" = "Kabyle"
        "kab-DZ" = "Kabyle (Algeria)"
        "kkj" = "Kako"
        "kkj-CM" = "Kako (Cameroon)"
        "kln" = "Kalenjin"
        "kln-KE" = "Kalenjin (Kenya)"
        "kam" = "Kamba"
        "kam-KE" = "Kamba (Kenya)"
        "kn" = "Kannada"
        "kn-IN" = "Kannada (India)"
        "kr" = "Kanuri"
        "kr-NG" = "Kanuri (Nigeria)"
        "ks" = "Kashmiri"
        "ks-Deva" = "Kashmiri (Devanagari)"
        "ks-Deva-IN" = "Kashmiri (Devanagari, India)"
        "ks-Arab" = "Kashmiri (Perso-Arabic)"
        "ks-Arab-IN" = "Kashmiri (Perso-Arabic)"
        "kk" = "Kazakh"
        "kk-KZ" = "Kazakh (Kazakhstan)"
        "km" = "Khmer"
        "km-KH" = "Khmer (Cambodia)"
        "quc-Latn" = "K'iche'"
        "quc" = "K'iche'"
        "quc-Latn-GT" = "K'iche' (Guatemala)"
        "ki" = "Kikuyu"
        "ki-KE" = "Kikuyu (Kenya)"
        "rw" = "Kinyarwanda"
        "rw-RW" = "Kinyarwanda (Rwanda)"
        "sw" = "Kiswahili"
        "sw-CD" = "Kiswahili (Congo DRC)"
        "sw-KE" = "Kiswahili (Kenya)"
        "sw-TZ" = "Kiswahili (Tanzania)"
        "sw-UG" = "Kiswahili (Uganda)"
        "kok" = "Konkani"
        "kok-IN" = "Konkani (India)"
        "ko" = "Korean"
        "ko-KR" = "Korean (Korea)"
        "ko-KP" = "Korean (North Korea)"
        "khq" = "Koyra Chiini"
        "khq-ML" = "Koyra Chiini (Mali)"
        "ses" = "Koyraboro Senni"
        "ses-ML" = "Koyraboro Senni (Mali)"
        "ku-Arab-IR" = "Kurdish (Perso-Arabic, Iran)"
        "nmg" = "Kwasio"
        "nmg-CM" = "Kwasio (Cameroon)"
        "ky" = "Kyrgyz"
        "ky-KG" = "Kyrgyz (Kyrgyzstan)"
        "lkt" = "Lakota"
        "lkt-US" = "Lakota (United States)"
        "lag" = "Langi"
        "lag-TZ" = "Langi (Tanzania)"
        "lo" = "Lao"
        "lo-LA" = "Lao (Lao P.D.R.)"
        "la" = "Latin"
        "la-001" = "Latin (World)"
        "lv" = "Latvian"
        "lv-LV" = "Latvian (Latvia)"
        "ln" = "Lingala"
        "ln-AO" = "Lingala (Angola)"
        "ln-CF" = "Lingala (Central African Republic)"
        "ln-CD" = "Lingala (Congo DRC)"
        "ln-CG" = "Lingala (Congo)"
        "lt" = "Lithuanian"
        "lt-LT" = "Lithuanian (Lithuania)"
        "nds" = "Low German"
        "nds-DE" = "Low German (Germany)"
        "nds-NL" = "Low German (Netherlands)"
        "dsb" = "Lower Sorbian"
        "dsb-DE" = "Lower Sorbian (Germany)"
        "lu" = "Luba-Katanga"
        "lu-CD" = "Luba-Katanga (Congo DRC)"
        "luo" = "Luo"
        "luo-KE" = "Luo (Kenya)"
        "lb" = "Luxembourgish"
        "lb-LU" = "Luxembourgish (Luxembourg)"
        "luy" = "Luyia"
        "luy-KE" = "Luyia (Kenya)"
        "mk-MK" = "Macedonian (Former Yugoslav Republic of Macedonia)"
        "mk" = "Macedonian (FYROM)"
        "jmc" = "Machame"
        "jmc-TZ" = "Machame (Tanzania)"
        "mgh" = "Makhuwa-Meetto"
        "mgh-MZ" = "Makhuwa-Meetto (Mozambique)"
        "kde" = "Makonde"
        "kde-TZ" = "Makonde (Tanzania)"
        "mg" = "Malagasy"
        "mg-MG" = "Malagasy (Madagascar)"
        "ms" = "Malay"
        "ms-BN" = "Malay (Brunei Darussalam)"
        "ms-SG" = "Malay (Latin, Singapore)"
        "ms-MY" = "Malay (Malaysia)"
        "ml" = "Malayalam"
        "ml-IN" = "Malayalam (India)"
        "mt" = "Maltese"
        "mt-MT" = "Maltese (Malta)"
        "mni" = "Manipuri"
        "mni-IN" = "Manipuri (India)"
        "gv" = "Manx"
        "gv-IM" = "Manx (Isle of Man)"
        "mi" = "Maori"
        "mi-NZ" = "Maori (New Zealand)"
        "arn" = "Mapudungun"
        "arn-CL" = "Mapudungun (Chile)"
        "mr" = "Marathi"
        "mr-IN" = "Marathi (India)"
        "mas" = "Masai"
        "mas-KE" = "Masai (Kenya)"
        "mas-TZ" = "Masai (Tanzania)"
        "mzn" = "Mazanderani"
        "mzn-IR" = "Mazanderani (Iran)"
        "mer" = "Meru"
        "mer-KE" = "Meru (Kenya)"
        "mgo" = "Meta'"
        "mgo-CM" = "Meta' (Cameroon)"
        "moh" = "Mohawk"
        "moh-CA" = "Mohawk (Mohawk)"
        "mn" = "Mongolian"
        "mn-Cyrl" = "Mongolian (Cyrillic)"
        "mn-MN" = "Mongolian (Cyrillic, Mongolia)"
        "mn-Mong" = "Mongolian (Traditional Mongolian)"
        "mn-Mong-MN" = "Mongolian (Traditional Mongolian, Mongolia)"
        "mn-Mong-CN" = "Mongolian (Traditional Mongolian, PRC)"
        "mfe" = "Morisyen"
        "mfe-MU" = "Morisyen (Mauritius)"
        "mua" = "Mundang"
        "mua-CM" = "Mundang (Cameroon)"
        "naq" = "Nama"
        "naq-NA" = "Nama (Namibia)"
        "ne" = "Nepali"
        "ne-IN" = "Nepali (India)"
        "ne-NP" = "Nepali (Nepal)"
        "nnh" = "Ngiemboon"
        "nnh-CM" = "Ngiemboon (Cameroon)"
        "jgo" = "Ngomba"
        "jgo-CM" = "Ngomba (Cameroon)"
        "nqo" = "N'ko"
        "nqo-GN" = "N'ko (Guinea)"
        "nd" = "North Ndebele"
        "nd-ZW" = "North Ndebele (Zimbabwe)"
        "lrc" = "Northern Luri"
        "lrc-IR" = "Northern Luri (Iran)"
        "lrc-IQ" = "Northern Luri (Iraq)"
        "no" = "Norwegian"
        "nb" = "Norwegian (Bokmål)"
        "nn" = "Norwegian (Nynorsk)"
        "nb-NO" = "Norwegian, Bokmål (Norway)"
        "nb-SJ" = "Norwegian, Bokmål (Svalbard and Jan Mayen)"
        "nn-NO" = "Norwegian, Nynorsk (Norway)"
        "nus" = "Nuer"
        "nus-SS" = "Nuer (South Sudan)"
        "nyn" = "Nyankole"
        "nyn-UG" = "Nyankole (Uganda)"
        "oc" = "Occitan"
        "oc-FR" = "Occitan (France)"
        "or" = "Odia"
        "or-IN" = "Odia (India)"
        "om" = "Oromo"
        "om-ET" = "Oromo (Ethiopia)"
        "om-KE" = "Oromo (Kenya)"
        "os-GE" = "Ossetian (Cyrillic, Georgia)"
        "os-RU" = "Ossetian (Cyrillic, Russia)"
        "os" = "Ossetic"
        "pap" = "Papiamento"
        "pap-029" = "Papiamento (Caribbean)"
        "ps" = "Pashto"
        "ps-AF" = "Pashto (Afghanistan)"
        "fa" = "Persian"
        "fa-IR" = "Persian (Iran)"
        "pl" = "Polish"
        "pl-PL" = "Polish (Poland)"
        "pt" = "Portuguese"
        "pt-AO" = "Portuguese (Angola)"
        "pt-BR" = "Portuguese (Brazil)"
        "pt-CV" = "Portuguese (Cabo Verde)"
        "pt-GQ" = "Portuguese (Equatorial Guinea)"
        "pt-GW" = "Portuguese (Guinea-Bissau)"
        "pt-LU" = "Portuguese (Luxembourg)"
        "pt-MO" = "Portuguese (Macao SAR)"
        "pt-MZ" = "Portuguese (Mozambique)"
        "pt-PT" = "Portuguese (Portugal)"
        "pt-ST" = "Portuguese (São Tomé and Príncipe)"
        "pt-CH" = "Portuguese (Switzerland)"
        "pt-TL" = "Portuguese (Timor-Leste)"
        "prg" = "Prussian"
        "prg-001" = "Prussian (World)"
        "pa" = "Punjabi"
        "pa-Arab" = "Punjabi (Arabic)"
        "pa-IN" = "Punjabi (India)"
        "pa-Arab-PK" = "Punjabi (Islamic Republic of Pakistan)"
        "quz" = "Quechua"
        "quz-BO" = "Quechua (Bolivia)"
        "quz-EC" = "Quechua (Ecuador)"
        "quz-PE" = "Quechua (Peru)"
        "ksh-DE" = "Ripuarian (Germany)"
        "ro" = "Romanian"
        "ro-MD" = "Romanian (Moldova)"
        "ro-RO" = "Romanian (Romania)"
        "rm" = "Romansh"
        "rm-CH" = "Romansh (Switzerland)"
        "rof" = "Rombo"
        "rof-TZ" = "Rombo (Tanzania)"
        "rn" = "Rundi"
        "rn-BI" = "Rundi (Burundi)"
        "ru" = "Russian"
        "ru-BY" = "Russian (Belarus)"
        "ru-KZ" = "Russian (Kazakhstan)"
        "ru-KG" = "Russian (Kyrgyzstan)"
        "ru-MD" = "Russian (Moldova)"
        "ru-RU" = "Russian (Russia)"
        "ru-UA" = "Russian (Ukraine)"
        "rwk" = "Rwa"
        "rwk-TZ" = "Rwa (Tanzania)"
        "ssy" = "Saho"
        "ssy-ER" = "Saho (Eritrea)"
        "sah" = "Sakha"
        "sah-RU" = "Sakha (Russia)"
        "saq" = "Samburu"
        "saq-KE" = "Samburu (Kenya)"
        "smn" = "Sami (Inari)"
        "smj" = "Sami (Lule)"
        "se" = "Sami (Northern)"
        "sms" = "Sami (Skolt)"
        "sma" = "Sami (Southern)"
        "smn-FI" = "Sami, Inari (Finland)"
        "smj-NO" = "Sami, Lule (Norway)"
        "smj-SE" = "Sami, Lule (Sweden)"
        "se-FI" = "Sami, Northern (Finland)"
        "se-NO" = "Sami, Northern (Norway)"
        "se-SE" = "Sami, Northern (Sweden)"
        "sms-FI" = "Sami, Skolt (Finland)"
        "sma-NO" = "Sami, Southern (Norway)"
        "sma-SE" = "Sami, Southern (Sweden)"
        "sg" = "Sango"
        "sg-CF" = "Sango (Central African Republic)"
        "sbp" = "Sangu"
        "sbp-TZ" = "Sangu (Tanzania)"
        "sa" = "Sanskrit"
        "sa-IN" = "Sanskrit (India)"
        "gd" = "Scottish Gaelic"
        "gd-GB" = "Scottish Gaelic (United Kingdom)"
        "seh" = "Sena"
        "seh-MZ" = "Sena (Mozambique)"
        "sr" = "Serbian"
        "sr-Cyrl" = "Serbian (Cyrillic)"
        "sr-Cyrl-BA" = "Serbian (Cyrillic, Bosnia and Herzegovina)"
        "sr-Cyrl-XK" = "Serbian (Cyrillic, Kosovo)"
        "sr-Cyrl-ME" = "Serbian (Cyrillic, Montenegro)"
        "sr-Cyrl-RS" = "Serbian (Cyrillic, Serbia)"
        "sr-Latn" = "Serbian (Latin)"
        "sr-Latn-BA" = "Serbian (Latin, Bosnia and Herzegovina)"
        "sr-Latn-XK" = "Serbian (Latin, Kosovo)"
        "sr-Latn-ME" = "Serbian (Latin, Montenegro)"
        "sr-Latn-RS" = "Serbian (Latin, Serbia)"
        "st-LS" = "Sesotho (Lesotho)"
        "nso" = "Sesotho sa Leboa"
        "nso-ZA" = "Sesotho sa Leboa (South Africa)"
        "tn" = "Setswana"
        "tn-BW" = "Setswana (Botswana)"
        "tn-ZA" = "Setswana (South Africa)"
        "ksb" = "Shambala"
        "ksb-TZ" = "Shambala (Tanzania)"
        "sn" = "Shona"
        "sn-Latn" = "Shona (Latin)"
        "sn-Latn-ZW" = "Shona (Latin, Zimbabwe)"
        "sd" = "Sindhi"
        "sd-Arab" = "Sindhi (Arabic)"
        "sd-Deva" = "Sindhi (Devanagari)"
        "sd-Deva-IN" = "Sindhi (Devanagari, India)"
        "sd-Arab-PK" = "Sindhi (Islamic Republic of Pakistan)"
        "si" = "Sinhala"
        "si-LK" = "Sinhala (Sri Lanka)"
        "sk" = "Slovak"
        "sk-SK" = "Slovak (Slovakia)"
        "sl" = "Slovenian"
        "sl-SI" = "Slovenian (Slovenia)"
        "xog" = "Soga"
        "xog-UG" = "Soga (Uganda)"
        "so" = "Somali"
        "so-DJ" = "Somali (Djibouti)"
        "so-ET" = "Somali (Ethiopia)"
        "so-KE" = "Somali (Kenya)"
        "so-SO" = "Somali (Somalia)"
        "nr" = "South Ndebele"
        "nr-ZA" = "South Ndebele (South Africa)"
        "st" = "Southern Sotho"
        "st-ZA" = "Southern Sotho (South Africa)"
        "es" = "Spanish"
        "es-AR" = "Spanish (Argentina)"
        "es-BZ" = "Spanish (Belize)"
        "es-VE" = "Spanish (Venezuela)"
        "es-BO" = "Spanish (Bolivia)"
        "es-BR" = "Spanish (Brazil)"
        "es-CL" = "Spanish (Chile)"
        "es-CO" = "Spanish (Colombia)"
        "es-CR" = "Spanish (Costa Rica)"
        "es-CU" = "Spanish (Cuba)"
        "es-DO" = "Spanish (Dominican Republic)"
        "es-EC" = "Spanish (Ecuador)"
        "es-SV" = "Spanish (El Salvador)"
        "es-GQ" = "Spanish (Equatorial Guinea)"
        "es-GT" = "Spanish (Guatemala)"
        "es-HN" = "Spanish (Honduras)"
        "es-419" = "Spanish (Latin America)"
        "es-MX" = "Spanish (Mexico)"
        "es-NI" = "Spanish (Nicaragua)"
        "es-PA" = "Spanish (Panama)"
        "es-PY" = "Spanish (Paraguay)"
        "es-PE" = "Spanish (Peru)"
        "es-PH" = "Spanish (Philippines)"
        "es-PR" = "Spanish (Puerto Rico)"
        "es-ES" = "Spanish (Spain)"
        "es-US" = "Spanish (United States)"
        "es-UY" = "Spanish (Uruguay)"
        "zgh" = "Standard Moroccan Tamazight"
        "zgh-Tfng" = "Standard Moroccan Tamazight (Tifinagh)"
        "zgh-Tfng-MA" = "Standard Moroccan Tamazight (Tifinagh, Morocco)"
        "ss" = "Swati"
        "ss-ZA" = "Swati (South Africa)"
        "ss-SZ" = "Swati (Eswatini former Swaziland)"
        "sv" = "Swedish"
        "sv-AX" = "Swedish (Åland Islands)"
        "sv-FI" = "Swedish (Finland)"
        "sv-SE" = "Swedish (Sweden)"
        "syr" = "Syriac"
        "syr-SY" = "Syriac (Syria)"
        "shi" = "Tachelhit"
        "shi-Latn" = "Tachelhit (Latin)"
        "shi-Latn-MA" = "Tachelhit (Latin, Morocco)"
        "shi-Tfng" = "Tachelhit (Tifinagh)"
        "shi-Tfng-MA" = "Tachelhit (Tifinagh, Morocco)"
        "dav" = "Taita"
        "dav-KE" = "Taita (Kenya)"
        "tg" = "Tajik"
        "tg-Cyrl" = "Tajik (Cyrillic)"
        "tg-Cyrl-TJ" = "Tajik (Cyrillic, Tajikistan)"
        "tzm" = "Tamazight"
        "tzm-Latn" = "Tamazight (Latin)"
        "tzm-Latn-DZ" = "Tamazight (Latin, Algeria)"
        "tzm-Tfng" = "Tamazight (Tifinagh)"
        "ta" = "Tamil"
        "ta-IN" = "Tamil (India)"
        "ta-MY" = "Tamil (Malaysia)"
        "ta-SG" = "Tamil (Singapore)"
        "ta-LK" = "Tamil (Sri Lanka)"
        "twq" = "Tasawaq"
        "twq-NE" = "Tasawaq (Niger)"
        "tt" = "Tatar"
        "tt-RU" = "Tatar (Russia)"
        "te" = "Telugu"
        "te-IN" = "Telugu (India)"
        "teo" = "Teso"
        "teo-KE" = "Teso (Kenya)"
        "teo-UG" = "Teso (Uganda)"
        "th" = "Thai"
        "th-TH" = "Thai (Thailand)"
        "bo" = "Tibetan"
        "bo-IN" = "Tibetan (India)"
        "bo-CN" = "Tibetan (PRC)"
        "tig" = "Tigre"
        "tig-ER" = "Tigre (Eritrea)"
        "ti" = "Tigrinya"
        "ti-ER" = "Tigrinya (Eritrea)"
        "ti-ET" = "Tigrinya (Ethiopia)"
        "to" = "Tongan"
        "to-TO" = "Tongan (Tonga)"
        "ts" = "Tsonga"
        "ts-ZA" = "Tsonga (South Africa)"
        "tr" = "Turkish"
        "tr-CY" = "Turkish (Cyprus)"
        "tr-TR" = "Turkish (Turkey)"
        "tk" = "Turkmen"
        "tk-TM" = "Turkmen (Turkmenistan)"
        "uk" = "Ukrainian"
        "uk-UA" = "Ukrainian (Ukraine)"
        "hsb" = "Upper Sorbian"
        "hsb-DE" = "Upper Sorbian (Germany)"
        "ur" = "Urdu"
        "ur-IN" = "Urdu (India)"
        "ur-PK" = "Urdu (Islamic Republic of Pakistan)"
        "ug" = "Uyghur"
        "ug-CN" = "Uyghur (PRC)"
        "uz" = "Uzbek"
        "uz-Cyrl" = "Uzbek (Cyrillic)"
        "uz-Cyrl-UZ" = "Uzbek (Cyrillic, Uzbekistan)"
        "uz-Latn" = "Uzbek (Latin)"
        "uz-Latn-UZ" = "Uzbek (Latin, Uzbekistan)"
        "uz-Arab" = "Uzbek (Perso-Arabic)"
        "uz-Arab-AF" = "Uzbek (Perso-Arabic, Afghanistan)"
        "vai" = "Vai"
        "vai-Latn" = "Vai (Latin)"
        "vai-Latn-LR" = "Vai (Latin, Liberia)"
        "vai-Vaii" = "Vai (Vai)"
        "vai-Vaii-LR" = "Vai (Vai, Liberia)"
        "ca-ES-valencia" = "Valencian (Spain)"
        "ve" = "Venda"
        "ve-ZA" = "Venda (South Africa)"
        "vi" = "Vietnamese"
        "vi-VN" = "Vietnamese (Vietnam)"
        "vo" = "Volapük"
        "vo-001" = "Volapük (World)"
        "vun" = "Vunjo"
        "vun-TZ" = "Vunjo (Tanzania)"
        "wae" = "Walser"
        "wae-CH" = "Walser (Switzerland)"
        "cy" = "Welsh"
        "cy-GB" = "Welsh (United Kingdom)"
        "wal" = "Wolaytta"
        "wal-ET" = "Wolaytta (Ethiopia)"
        "wo" = "Wolof"
        "wo-SN" = "Wolof (Senegal)"
        "yav" = "Yangben"
        "yav-CM" = "Yangben (Cameroon)"
        "ii" = "Yi"
        "ii-CN" = "Yi (PRC)"
        "yi" = "Yiddish"
        "yi-001" = "Yiddish (World)"
        "yo" = "Yoruba"
        "yo-BJ" = "Yoruba (Benin)"
        "yo-NG" = "Yoruba (Nigeria)"
        "dje" = "Zarma"
        "dje-NE" = "Zarma (Niger)"
    }

    # Get the current user's language and region using the registry
    $Region = $localeLookup[(Get-ItemProperty -Path "HKCU:Control Panel\International\Geo").Nation]
    # TODO - Create Scenario for when user has more than one language
    $Language = $languageLookup[(Get-ItemProperty -Path "HKCU:Control Panel\International\User Profile").Languages]

    return @{
        title = "Locale"
        content = "$Region - $Language"
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
