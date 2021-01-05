# ===== WINFETCH CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Add a custom info line
# function info_custom_time {
#     return @{
#         title = "Time"
#         content = (Get-Date)
#     }
# }

# Remove the '#' from any of the lines in
# the following to **enable** their output.

@(
    "title"
    "dashes"
    "os"
    "computer"
    # "custom_time"  # use custom info line
    "uptime"
    "resolution"
    # "pkgs" # might take slightly more time
    "pwsh"
    "terminal"
    "cpu"
    "gpu"
    "memory"
    "disk"
    "blank"
    "colorbar"
)
