param(
    [int]$MaxToDelete = 100000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace Win32 {
    public static class User32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
}
"@

function Get-ArrayFromCollection {
    param([System.Windows.Automation.AutomationElementCollection]$Collection)
    $items = @()
    for ($i = 0; $i -lt $Collection.Count; $i++) {
        $items += $Collection.Item($i)
    }
    return $items
}

function Get-RuntimeIdKey {
    param([System.Windows.Automation.AutomationElement]$Element)
    return (($Element.GetRuntimeId() | ForEach-Object { $_.ToString() }) -join "-")
}

function Get-ChromeProcess {
    $process = Get-Process -Name chrome -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } |
        Select-Object -First 1
    if (-not $process) {
        throw "Google Chrome is not running. Open Chrome first, then run this script again."
    }
    return $process
}

function Focus-Chrome {
    param([System.Diagnostics.Process]$ChromeProcess)
    [void][Win32.User32]::SetForegroundWindow($ChromeProcess.MainWindowHandle)
    Start-Sleep -Milliseconds 250
}

function Send-Escapes {
    param([System.Diagnostics.Process]$ChromeProcess)
    Focus-Chrome -ChromeProcess $ChromeProcess
    for ($i = 0; $i -lt 4; $i++) {
        [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
        Start-Sleep -Milliseconds 120
    }
}

function Get-VisibleMenus {
    param([int]$ProcessId)
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $menuCondition = New-Object System.Windows.Automation.AndCondition(
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::Menu
        )),
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ProcessIdProperty,
            $ProcessId
        )),
        (New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::IsOffscreenProperty,
            $false
        ))
    )
    return Get-ArrayFromCollection -Collection ($root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $menuCondition))
}

function Get-MenuItems {
    param([System.Windows.Automation.AutomationElement]$Menu)
    $itemCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::MenuItem
    )
    return Get-ArrayFromCollection -Collection ($Menu.FindAll([System.Windows.Automation.TreeScope]::Children, $itemCondition))
}

function Invoke-MenuItem {
    param([System.Windows.Automation.AutomationElement]$MenuItem)
    if ($MenuItem.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$patternObject)) {
        ([System.Windows.Automation.InvokePattern]$patternObject).Invoke()
        return
    }
    throw "Menu item '$($MenuItem.Current.Name)' cannot be invoked."
}

function Expand-MenuItem {
    param([System.Windows.Automation.AutomationElement]$MenuItem)
    if ($MenuItem.TryGetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern, [ref]$patternObject)) {
        $pattern = [System.Windows.Automation.ExpandCollapsePattern]$patternObject
        if ($pattern.Current.ExpandCollapseState -ne [System.Windows.Automation.ExpandCollapseState]::Expanded) {
            $pattern.Expand()
        }
        return
    }
    Invoke-MenuItem -MenuItem $MenuItem
}

function Find-MenuItemByName {
    param(
        [System.Windows.Automation.AutomationElement[]]$Items,
        [scriptblock]$Predicate
    )
    foreach ($item in $Items) {
        if (& $Predicate $item.Current.Name) {
            return $item
        }
    }
    return $null
}

function Get-NewVisibleMenu {
    param(
        [int]$ProcessId,
        [string[]]$ExcludeRuntimeKeys
    )
    for ($attempt = 0; $attempt -lt 12; $attempt++) {
        $menus = Get-VisibleMenus -ProcessId $ProcessId
        $candidateMenus = @()
        foreach ($menu in $menus) {
            $key = Get-RuntimeIdKey -Element $menu
            if ($ExcludeRuntimeKeys -contains $key) { continue }
            $candidateMenus += $menu
        }
        if ($candidateMenus.Count -gt 0) {
            return ($candidateMenus | Sort-Object { $_.Current.BoundingRectangle.Left } -Descending | Select-Object -First 1)
        }
        Start-Sleep -Milliseconds 120
    }
    return $null
}

function Open-TabGroupsSubmenu {
    param([System.Diagnostics.Process]$ChromeProcess)

    Focus-Chrome -ChromeProcess $ChromeProcess

    $chromeWindow = [System.Windows.Automation.AutomationElement]::FromHandle($ChromeProcess.MainWindowHandle)
    $buttonCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Button
    )
    $buttons = Get-ArrayFromCollection -Collection ($chromeWindow.FindAll([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition))
    $menuButton = Find-MenuItemByName -Items $buttons -Predicate { param($name) $name -like "*Customize and control*" }
    if (-not $menuButton) {
        throw "Could not find Chrome's main menu button."
    }

    Invoke-MenuItem -MenuItem $menuButton
    Start-Sleep -Milliseconds 350

    $visibleMenus = Get-VisibleMenus -ProcessId $ChromeProcess.Id
    if ($visibleMenus.Count -eq 0) {
        throw "Could not open Chrome's main menu."
    }
    $mainMenu = $visibleMenus | Sort-Object { (Get-MenuItems -Menu $_).Count } -Descending | Select-Object -First 1

    $mainItems = Get-MenuItems -Menu $mainMenu
    $tabGroupsItem = Find-MenuItemByName -Items $mainItems -Predicate { param($name) $name -eq "Tab groups" -or $name -eq "Tab group" }
    if (-not $tabGroupsItem) {
        Send-Escapes -ChromeProcess $ChromeProcess
        throw "Could not find 'Tab groups' in Chrome's main menu. Ensure your Chrome UI language is English."
    }

    $existingMenuKeys = @()
    foreach ($menu in $visibleMenus) {
        $existingMenuKeys += Get-RuntimeIdKey -Element $menu
    }

    Expand-MenuItem -MenuItem $tabGroupsItem
    Start-Sleep -Milliseconds 220

    $tabGroupsSubmenu = Get-NewVisibleMenu -ProcessId $ChromeProcess.Id -ExcludeRuntimeKeys $existingMenuKeys
    if (-not $tabGroupsSubmenu) {
        throw "Could not open the Tab groups submenu."
    }

    return [PSCustomObject]@{
        MainMenu = $mainMenu
        Submenu  = $tabGroupsSubmenu
    }
}

function Delete-FirstClosedGroup {
    param([System.Diagnostics.Process]$ChromeProcess)

    $menus = Open-TabGroupsSubmenu -ChromeProcess $ChromeProcess
    $tabGroupsMenu = $menus.Submenu
    $groupItems = Get-MenuItems -Menu $tabGroupsMenu

    $closedGroup = Find-MenuItemByName -Items $groupItems -Predicate { param($name) $name -match "group - Closed$" }
    if (-not $closedGroup) {
        Send-Escapes -ChromeProcess $ChromeProcess
        return ""
    }

    $targetName = $closedGroup.Current.Name
    $existingKeys = @(
        (Get-RuntimeIdKey -Element $menus.MainMenu),
        (Get-RuntimeIdKey -Element $tabGroupsMenu)
    )

    Expand-MenuItem -MenuItem $closedGroup
    Start-Sleep -Milliseconds 220

    $groupMenu = Get-NewVisibleMenu -ProcessId $ChromeProcess.Id -ExcludeRuntimeKeys $existingKeys
    if (-not $groupMenu) {
        Send-Escapes -ChromeProcess $ChromeProcess
        throw "Could not open submenu for '$targetName'."
    }

    $actions = Get-MenuItems -Menu $groupMenu
    $deleteItem = Find-MenuItemByName -Items $actions -Predicate { param($name) $name -eq "Delete group" }
    if (-not $deleteItem) {
        Send-Escapes -ChromeProcess $ChromeProcess
        throw "Could not find 'Delete group' for '$targetName'."
    }

    Invoke-MenuItem -MenuItem $deleteItem
    Start-Sleep -Milliseconds 350
    Send-Escapes -ChromeProcess $ChromeProcess
    return $targetName
}

$chrome = Get-ChromeProcess
Focus-Chrome -ChromeProcess $chrome

$deleted = 0
$failures = 0

while ($deleted -lt $MaxToDelete) {
    try {
        $groupName = Delete-FirstClosedGroup -ChromeProcess $chrome
        if ([string]::IsNullOrWhiteSpace($groupName)) { break }
        $deleted++
        Write-Host "Deleted #$deleted : $groupName"
        $failures = 0
    }
    catch {
        $failures++
        Write-Host "Retry after error: $($_.Exception.Message)"
        Send-Escapes -ChromeProcess $chrome
        Start-Sleep -Seconds 1
        if ($failures -ge 3) { break }
    }
}

Write-Host "Done. Deleted $deleted saved tab group(s)."
