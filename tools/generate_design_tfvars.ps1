param(
    [string]$Excel = ".\design\azure_landingzone_design.xlsx",
    [string]$Out = ".\generated_tfvars",
    [switch]$PublishLive,
    [switch]$AllowPlaceholders
)

$ErrorActionPreference = "Stop"

$argsList = @(
    ".\tools\excel_design_to_auto_tfvars.py",
    "--excel", $Excel,
    "--out", $Out
)

if ($PublishLive) {
    $argsList += @("--publish-live", "--live-root", ".\live")
}
if ($AllowPlaceholders) {
    $argsList += "--allow-placeholders"
}

python @argsList
if ($LASTEXITCODE -ne 0) {
    throw "Excel design conversion failed."
}
