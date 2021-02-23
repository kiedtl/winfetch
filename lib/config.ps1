# ===== WINFETCH CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Use legacy Windows logo
# $legacylogo = $true

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
# $ShowPkgs = @("scoop", "choco")


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
    "pkgs"
    "pwsh"
    "resolution"
    "terminal"
    # "theme"
    "cpu"
    "gpu"
    # "process" # takes some time
    "memory"
    "disk"
    # "battery"
    # "locale"
    # "local_ip"
    # "public_ip"
    "blank"
    "colorbar"
)
