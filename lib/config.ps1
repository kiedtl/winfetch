# ===== WINFETCH CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Use legacy Windows logo
# $legacylogo = $true

# Make the logo blink
# $blink = $true

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
    "cpu"
    "gpu"
    "memory"
    "disk"
    # "battery"
    # "local_ip"
    # "public_ip"
    "blank"
    "colorbar"
)
