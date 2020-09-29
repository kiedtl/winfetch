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

$colorBar = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}' +
            '{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}' +
            '{0}[0m') -f $e, '   '

$is_pscore = if ($PSVersionTable.PSEdition.ToString() -eq 'Core') {
    $true
} else {
    $false
}

$configdir = $env:XDG_CONFIG_HOME, "${env:USERPROFILE}\.config" | Select-Object -First 1
$config = "${configdir}/winfetch/config.ps1"

$defaultconfig = 'https://raw.githubusercontent.com/lptstr/winfetch/master/lib/config.ps1'

# ensure configuration directory exists
if (-not (Test-Path -Path $config)) {
    [void](New-Item -Path $config -Force)
}

# ===== DISPLAY HELP =====
if ($help) {
    if (Get-Command -Name less -ErrorAction Ignore) {
        get-help ($MyInvocation.MyCommand.Definition) -full | less
    } else {
        get-help ($MyInvocation.MyCommand.Definition) -full
    }
    exit 0
}

# ===== GENERATE CONFIGURATION =====
if ($genconf.IsPresent) {
    if ((Get-Item -Path $config).Length -gt 0) {
        Write-Host 'ERROR: configuration file already exists!' -f red
        exit 1
    }
    "INFO: downloading default config to '$config'."
    Invoke-WebRequest -Uri $defaultconfig -OutFile $config -UseBasicParsing
    'INFO: successfully completed download.'
    exit 0
}


# ===== VARIABLES =====
$disabled = 'disabled'
$strings = @{
    title    = ''
    dashes   = ''
    img      = ''
    os       = ''
    hostname = ''
    username = ''
    computer = ''
    uptime   = ''
    terminal = ''
    cpu      = ''
    gpu      = ''
    memory   = ''
    disk     = ''
    pwsh     = ''
    pkgs     = ''
}


# ===== CONFIGURATION =====
[Flags()]
enum Configuration
{
    None          = 0
    Show_Title    = 1
    Show_Dashes   = 2
    Show_OS       = 4
    Show_Computer = 8
    Show_Uptime   = 16
    Show_Terminal = 32
    Show_CPU      = 64
    Show_GPU      = 128
    Show_Memory   = 256
    Show_Disk     = 512
    Show_Pwsh     = 1024
    Show_Pkgs     = 2048
}
[Configuration]$configuration = if ((Get-Item -Path $config).Length -gt 0) {
    . $config
}
else {
    0xFFF
}


# ===== IMAGE =====
$img = if (-not $image -and -not $noimage.IsPresent) {
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
elseif (-not $noimage.IsPresent -and $image) {
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
    if (-not (test-path -path $image)) {
        Write-Host 'ERROR: Specified image or wallpaper does not exist.' -f red
        exit 1
    }
    $pixels = @((magick convert -thumbnail "${COLUMNS}x" -define txt:compliance=SVG $image txt:-).Split("`n"))
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


# ===== OS =====
$strings.os = if ($configuration.HasFlag([Configuration]::Show_OS)) {
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5) {
        [Environment]::OSVersion.ToString().TrimStart('Microsoft ')
    } else {
        ($PSVersionTable.OS).TrimStart('Microsoft ')
    }
} else {
    $disabled
}


# ===== HOSTNAME =====
$strings.hostname = $Env:COMPUTERNAME


# ===== USERNAME =====
$strings.username = [Environment]::UserName


# ===== TITLE =====
$strings.title = if ($configuration.HasFlag([Configuration]::Show_Title)) {
    "${e}[1;34m{0}${e}[0m@${e}[1;34m{1}${e}[0m" -f $strings['username', 'hostname']
} else {
    $disabled
}


# ===== DASHES =====
$strings.dashes = if ($configuration.HasFlag([Configuration]::Show_Dashes)) {
    -join $(for ($i = 0; $i -lt ('{0}@{1}' -f $strings['username', 'hostname']).Length; $i++) { '-' })
} else {
    $disabled
}


# ===== COMPUTER =====
$strings.computer = if ($configuration.HasFlag([Configuration]::Show_Computer)) {
    $compsys = Get-CimInstance -ClassName Win32_ComputerSystem
    '{0} {1}' -f $compsys.Manufacturer, $compsys.Model
} else {
    $disabled
}


# ===== UPTIME =====
$strings.uptime = if ($configuration.HasFlag([Configuration]::Show_Uptime)) {
    $(switch ((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime) {
        ({ $PSItem.Days -eq 1 }) { '1 day' }
        ({ $PSItem.Days -gt 1 }) { "$($PSItem.Days) days" }
        ({ $PSItem.Hours -eq 1 }) { '1 hour' }
        ({ $PSItem.Hours -gt 1 }) { "$($PSItem.Hours) hours" }
        ({ $PSItem.Minutes -eq 1 }) { '1 minute' }
        ({ $PSItem.Minutes -gt 1 }) { "$($PSItem.Minutes) minutes" }
    }) -join ' '
} else {
    $disabled
}


# ===== TERMINAL =====
# this section works by getting
# the parent processes of the
# current powershell instance.
$strings.terminal = if ($configuration.HasFlag([Configuration]::Show_Terminal) -and $is_pscore) {
    $parent = (Get-Process -Id $PID).Parent
    if(-not $parent -and $env:WT_SESSION) {
        'Windows Terminal'
    } else {
        for () {
            if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
                $parent = (Get-Process -Id $parent.ID).Parent
                continue
            }
            break
        }
        try {
            switch ($parent.ProcessName) {
                'explorer' { 'Windows Console' }
                default { $PSItem }
            }
        } catch {
            $parent.ProcessName
        }
    }
} else {
    $disabled
}


# ===== CPU/GPU =====
$strings.cpu = if ($configuration.HasFlag([Configuration]::Show_CPU)) {
    (Get-CimInstance -ClassName Win32_Processor).Name
} else {
    $disabled
}

$strings.gpu = if ($configuration.HasFlag([Configuration]::Show_GPU)) {
    (Get-CimInstance -ClassName Win32_VideoController).Name
} else {
    $disabled
}


# ===== MEMORY =====
$strings.memory = if ($configuration.HasFlag([Configuration]::Show_Memory)) {
    $m = Get-CimInstance -ClassName Win32_OperatingSystem
    $total = [math]::floor(($m.TotalVisibleMemorySize / 1mb))
    $used = [math]::floor((($m.FreePhysicalMemory - $total) / 1mb))
    ("{0}GiB / {1}GiB" -f $used,$total)
} else {
    $disabled
}


# ===== DISK USAGE =====
$strings.disk = if ($configuration.HasFlag([Configuration]::Show_Disk)) {
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID="C:"'
    $total = [math]::floor(($disk.Size / 1gb))
    $used = [math]::floor((($disk.FreeSpace - $total) / 1gb))
    $usage = [math]::floor(($used / $total * 100))
    ("{0}GiB / {1}GiB ({2}%)" -f $used,$total,$usage)
} else {
    $disabled
}


# ===== POWERSHELL VERSION =====
$strings.pwsh = if ($configuration.HasFlag([Configuration]::Show_Pwsh)) {
    "PowerShell v$($PSVersionTable.PSVersion)"
} else {
    $disabled
}


# ===== PACKAGES =====
$strings.pkgs = if ($configuration.HasFlag([Configuration]::Show_Pkgs)) {
    $chocopkg = if (Get-Command -Name choco -ErrorAction Ignore) {
        (& clist -l)[-1].Split(' ')[0] - 1
    }

    $scooppkg = if (Get-Command -Name scoop -ErrorAction Ignore) {
        $scoop = & scoop which scoop
        $scoopdir = (Resolve-Path "$(Split-Path -Path $scoop)\..\..\..").Path
        (Get-ChildItem -Path $scoopdir -Directory).Count - 1
    }

    $(if ($scooppkg) {
        "$scooppkg (scoop)"
    }
    if ($chocopkg) {
        "$chocopkg (choco)"
    }) -join ', '
} else {
    $disabled
}


# reset terminal sequences and display a newline
write-output "${e}[0m"

# add system info into an array
$info = [collections.generic.list[string[]]]::new()
$info.Add(@("", $strings.title))
$info.Add(@("", $strings.dashes))
$info.Add(@("OS", $strings.os))
$info.Add(@("Host", $strings.computer))
$info.Add(@("Uptime", $strings.uptime))
$info.Add(@("Packages", $strings.pkgs))
$info.Add(@("PowerShell", $strings.pwsh))
$info.Add(@("Terminal", $strings.terminal))
$info.Add(@("CPU", $strings.cpu))
$info.Add(@("GPU", $strings.gpu))
$info.Add(@("Memory", $strings.memory))
$info.Add(@("Disk (C:)", $strings.disk))
$info.Add(@("", ""))
$info.Add(@("", $colorBar))

# write system information in a loop
$counter = 0
$logoctr = 0
while ($counter -lt $info.Count) {
    $logo_line = $img[$logoctr]
    $item_title = "$e[1;34m$($info[$counter][0])$e[0m"
    $item_content = if (($info[$counter][0]) -eq '') {
            $($info[$counter][1])
        } else {
            ": $($info[$counter][1])"
        }

    if ($item_content -notlike '*disabled') {
        " ${logo_line}$e[40G${item_title}${item_content}"
    }

    $counter++
    if ($item_content -notlike '*disabled') {
        $logoctr++
    }
}

# print the rest of the logo
if ($logoctr -lt $img.Count) {
    while ($logoctr -le $img.Count) {
        " $($img[$logoctr])"
        $logoctr++
    }
}

# print a newline
write-output ''

#  ___ ___  ___
# | __/ _ \| __|
# | _| (_) | _|
# |___\___/|_|
#
