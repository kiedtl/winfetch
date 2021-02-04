#!/usr/bin/env pwsh
#requires -version 5

# The MIT License (MIT)
# Copyright (c) 2019 Kied Llaentenn and contributers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

<#PSScriptInfo
.VERSION 1.2.1
.GUID 1c26142a-da43-4125-9d70-97555cbb1752
.DESCRIPTION Winfetch is a command-line system information utility for Windows written in PowerShell.
.AUTHOR lptstr
.PROJECTURI https://github.com/lptstr/winfetch
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI
.ICONURI
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
    Display a pixelated image instead of the usual logo. Imagemagick required.
.PARAMETER genconf
    Download a configuration template. Internet connection required.
.PARAMETER noimage
    Do not display any image or logo; display information only.
.PARAMETER help
    Display this help message.
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
    [switch][alias('g')]$genconf,
    [switch][alias('n')]$noimage,
    [switch][alias('h')]$help
)

$e = [char]0x1B

$is_pscore = $PSVersionTable.PSEdition.ToString() -eq 'Core'

$configdir = $env:XDG_CONFIG_HOME, "${env:USERPROFILE}\.config" | Select-Object -First 1
$configPath = "${configdir}/winfetch/config.ps1"

$defaultconfig = 'https://raw.githubusercontent.com/lptstr/winfetch/master/lib/config.ps1'

# ensure configuration directory exists
if (-not (Test-Path -Path $configPath)) {
    [void](New-Item -Path $configPath -Force)
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

# ===== GENERATE CONFIGURATION =====
if ($genconf) {
    if ((Get-Item -Path $configPath).Length -gt 0) {
        Write-Host 'ERROR: configuration file already exists!' -f red
        exit 1
    }
    Write-Output "INFO: downloading default config to '$configPath'."
    Invoke-WebRequest -Uri $defaultconfig -OutFile $configPath -UseBasicParsing
    Write-Output 'INFO: successfully completed download.'
    exit 0
}


# ===== VARIABLES =====
$cimSession = New-CimSession
$showDisks = @($env:SystemDrive)


# ===== CONFIGURATION =====
$baseConfig = @(
    "title"
    "dashes"
    "os"
    "computer"
    "kernel"
    "motherboard"
    "uptime"
    "resolution"
    "pkgs"
    "pwsh"
    "terminal"
    "cpu"
    "gpu"
    "memory"
    "disk"
    "battery"
    "local_ip"
    "public_ip"
    "blank"
    "colorbar"
)

if ((Get-Item -Path $configPath).Length -gt 0) {
    $config = . $configPath
} else {
    $config = $baseConfig
}

# convert old config style
if ($config.GetType() -eq [string]) {
    $oldConfig = $config.ToLower()
    $config = $baseConfig | Where-Object { $oldConfig.Contains($_) }
    $config += @("blank", "colorbar")
}


# ===== IMAGE =====
$img = if (-not $image -and -not $noimage) {
    @(
        "${e}[1;34m                    ....,,:;+ccllll${e}[0m"
        "${e}[1;34m      ...,,+:;  cllllllllllllllllll${e}[0m"
        "${e}[1;34m,cclllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34m                                   ${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34mllllllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34m``'ccllllllllll  lllllllllllllllllll${e}[0m"
        "${e}[1;34m      ``' \\*::  :ccllllllllllllllll${e}[0m"
        "${e}[1;34m                       ````````''*::cll${e}[0m"
        "${e}[1;34m                                 ````${e}[0m"
    )
}
elseif (-not $noimage -and $image) {
    if (-not (Get-Command -Name magick -ErrorAction Ignore)) {
        Write-Host 'ERROR: Imagemagick must be installed to print custom images.' -f red
        Write-Host 'hint: if you have Scoop installed, try `scoop install imagemagick`.' -f yellow
        exit 1
    }

    $COLUMNS = 35
    $CURR_ROW = ""
    $CHAR = [Text.Encoding]::UTF8.GetString(@(226, 150, 128)) # 226,150,136
    $upper, $lower = @(), @()

    if ($image -eq 'wallpaper') {
        $image = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    }
    if (-not (Test-Path -path $image)) {
        Write-Host 'ERROR: Specified image or wallpaper does not exist.' -f red
        exit 1
    }

    $tempImg = [IO.Path]::GetTempFileName()
    magick convert $image -resize "${COLUMNS}x" $tempImg
    $pixels = @((magick convert -thumbnail "${COLUMNS}x" -define txt:compliance=SVG $tempImg txt:-).Split("`n"))
    Remove-Item $tempImg

    foreach ($pixel in $pixels) {
        $coord = [regex]::Match($pixel, "([0-9])+,([0-9])+:").Value.TrimEnd(":") -split ','
        $col, $row = $coord[0, 1]

        $rgba = [regex]::Match($pixel, "\(([0-9])+,([0-9])+,([0-9])+,([0-9])+\)").Value.TrimStart("(").TrimEnd(")").Split(",")
        $r, $g, $b = $rgba[0, 1, 2]

        if (($row % 2) -eq 0) {
            $upper += "${r};${g};${b}"
        } else {
            $lower += "${r};${g};${b}"
        }

        if (($row % 2) -eq 1 -and $col -eq ($COLUMNS - 1)) {
            $i = 0
            while ($i -lt $COLUMNS) {
                $CURR_ROW += "${e}[38;2;$($upper[$i]);48;2;$($lower[$i])m${CHAR}"
                $i++
            }
            "${CURR_ROW}${e}[0m"

            $CURR_ROW = ""
            $upper = @()
            $lower = @()
        }
    }
}
else {
    @()
}


# ===== BLANK =====
function info_blank {
    return @{}
}


# ===== COLORBAR =====
function info_colorbar {
    return @{
        title   = ""
        content = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}' +
            '{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}' +
            '{0}[0m') -f $e, '   '
    }
}


# ===== OS =====
function info_os {
    return @{
        title   = "OS"
        content = if ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5) {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption,OSArchitecture -CimSession $cimSession
            "$($os.Caption.TrimStart('Microsoft ')) [$($os.OSArchitecture)]"
        } else {
            ($PSVersionTable.OS).TrimStart('Microsoft ')
        }
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
        content = "${e}[1;34m{0}${e}[0m@${e}[1;34m{1}${e}[0m" -f [Environment]::UserName,$env:COMPUTERNAME
    }
}


# ===== DASHES =====
function info_dashes {
    $length = [Environment]::UserName.Length + $env:COMPUTERNAME.Length + 1
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
        content = if ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5) {
            "$([System.Environment]::OSVersion.Version)"
        } else {
            "$(uname -r)"
        }
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
    $Displays = New-Object System.Collections.Generic.List[System.Object];
    foreach ($monitor in [System.Windows.Forms.Screen]::AllScreens) {
        $Displays.Add("$($monitor.Bounds.Size.Width)x$($monitor.Bounds.Size.Height)");
    }

    return @{
        title   = "Resolution"
        content = $Displays -join ' '
    }
}


# ===== TERMINAL =====
# this section works by getting the parent processes of the current powershell instance.
function info_terminal {
    if (-not $is_pscore) {
        $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID" -Property ParentProcessId -CimSession $cimSession).ParentProcessId
        for () {
            if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
                $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($parent.ID)" -Property ParentProcessId -CimSession $cimSession).ParentProcessId
                continue
            }
            break
        }
    } else {
        $parent = (Get-Process -Id $PID).Parent
        for () {
            if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
                $parent = (Get-Process -Id $parent.ID).Parent
                continue
            }
            break
        }
    }
    try {
        $terminal = switch ($parent.ProcessName) {
            'explorer' { 'Windows Console' }
            'WindowsTerminal' { 'Windows Terminal' }
            'Code' { 'Visual Studio Code' }
            default { $PSItem }
        }
    } catch {
        $terminal = $parent.ProcessName
    }

    return @{
        title   = "Terminal"
        content = $terminal
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
    return @{
        title   = "GPU"
        content = (Get-CimInstance -ClassName Win32_VideoController -Property Name -CimSession $cimSession).Name
    }
}


# ===== MEMORY =====
function info_memory {
    $m = Get-CimInstance -ClassName Win32_OperatingSystem -Property TotalVisibleMemorySize,FreePhysicalMemory -CimSession $cimSession
    $total = $m.TotalVisibleMemorySize / 1mb
    $used = ($m.TotalVisibleMemorySize - $m.FreePhysicalMemory) / 1mb
    return @{
        title   = "Memory"
        content = ("{0:f1} GiB / {1:f1} GiB" -f $used,$total)
    }
}


# ===== DISK USAGE =====
function info_disk {
    [System.Collections.ArrayList]$lines = @()

    function to_units($value) {
        if ($value -gt 1tb) {
            return "$([math]::round($value / 1tb, 1))T"
        } else {
            return "$([math]::floor($value / 1gb))G"
        }
    }

    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Property Size,FreeSpace -CimSession $cimSession

    foreach ($diskInfo in $disks) {
        foreach ($diskLetter in $showDisks) {
            if ($diskInfo.DeviceID -eq $diskLetter -or $diskLetter -eq "*") {
                $total = $diskInfo.Size
                $used = $total - $diskInfo.FreeSpace
                $usage = [math]::floor(($used / $total * 100))
                [void]$lines.Add(@{
                    title   = "Disk ($($diskInfo.DeviceID))"
                    content = "$(to_units $used) / $(to_units $total) ($usage%)"
                })
                break
            }
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


# ===== PACKAGES =====
function info_pkgs {
    $chocopkg = if (Get-Command -Name choco -ErrorAction Ignore) {
        (& clist -l)[-1].Split(' ')[0] - 1
    }

    $scooppkg = if (Get-Command -Name scoop -ErrorAction Ignore) {
        $scoop = & scoop which scoop
        $scoopdir = (Resolve-Path "$(Split-Path -Path $scoop)\..\..\..").Path
        (Get-ChildItem -Path $scoopdir -Directory).Count - 1
    }

    $pkgs = $(if ($scooppkg) {
        "$scooppkg (scoop)"
    }
    if ($chocopkg) {
        "$chocopkg (choco)"
    }) -join ', '

    return @{
        title   = "Packages"
        content = $pkgs
    }
}


# ===== BATTERY =====
function info_battery {
    $battery = Get-CimInstance Win32_Battery -CimSession $cimSession -Property BatteryStatus,EstimatedChargeRemaining,EstimatedRunTime,TimeToFullCharge

    if (-not $battery) {
        return @{
            title = "Battery"
            content = "(none)"
        }
    }

    $power = Get-CimInstance BatteryStatus -Namespace root\wmi -CimSession $cimSession -Property Charging,PowerOnline

    $status = if ($power.Charging) {
        "Charging"
    } elseif ($power.PowerOnline) {
        "Plugged in"
    } else {
        "Discharging"
    }

    $timeRemaining = if ($power.Charging) {
        $battery.TimeToFullCharge
    } else {
        $battery.EstimatedRunTime
    }

    # don't show time remaining if windows hasn't properly reported it yet
    $timeFormatted = if ($timeRemaining -and $timeRemaining -lt 71582788) {
        $hours = [math]::floor($timeRemaining / 60)
        $minutes = $timeRemaining % 60
        ", ${hours}h ${minutes}m"
    }

    return @{
        title = "Battery"
        content = "$($battery.EstimatedChargeRemaining)% ($status$timeFormatted)"
    }
}


# ===== IP =====
function info_local_ip {
    $indexDefault = Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object -Property RouteMetric | Select-Object -First 1 | Select-Object -ExpandProperty ifIndex
    $local_ip = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $indexDefault | Select-Object -ExpandProperty IPAddress
    return @{
        title = "Local IP"
        content = $local_ip
    }
}

function info_public_ip {
    try {
        $public_ip = (Resolve-DnsName -Name myip.opendns.com -Server resolver1.opendns.com).IPAddress
    } catch {}

    if (-not $public_ip) {
        $public_ip = Invoke-RestMethod -Uri https://ifconfig.me/ip
    }

    return @{
        title = "Public IP"
        content = $public_ip
    }
}


# reset terminal sequences and display a newline
Write-Host "$e[0m"

# write logo
foreach ($line in $img) {
    Write-Host " $line"
}

# move cursor to top of image and to column 40
if ($img) {
    Write-Host -NoNewLine "$e[$($img.Length)A$e[40G"
    $writtenLines = 0
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
        $output = "$e[1;34m$($line["title"])$e[0m"

        if ($line["title"] -and $line["content"]) {
            $output += ": "
        }

        $output += "$($line["content"])`n"

        # move cursor to column 40
        if ($img) {
            $output += "$e[40G"
            $writtenLines++
        }

        Write-Host -NoNewLine $output
    }
}

# move cursor back to the bottom
if ($img) {
    Write-Host -NoNewLine "$e[$($img.Length - $writtenLines)B"
}

# print 2 newlines
Write-Host "`n"

#  ___ ___  ___
# | __/ _ \| __|
# | _| (_) | _|
# |___\___/|_|
#
