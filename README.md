# delete-chrome-tab-groups

Automation tools to bulk-delete saved tab groups from Google Chrome's **⋮ > Tab groups** menu on macOS and Windows.

## Background & Why This Exists

In Google Chrome, saved tab groups are synced across your devices via your Google Account. 
- Chrome Extension APIs (`chrome.tabGroups`, `chrome.tabs`) **only** have access to active, open tab groups in the current window. They cannot access, query, or delete saved tab groups that are closed.
- Manually deleting hundreds of saved tab groups through the Chrome menu one-by-one is tedious and time-consuming.

These tools automate Chrome's native UI navigation to cleanly and permanently delete all closed saved tab groups in bulk.

> [!NOTE]
> **Safety:** The script only deletes tab groups with the status **"Closed"**. Tab groups that are currently open in your browser are left untouched to prevent accidentally closing your active tabs.

---

## Prerequisites

### macOS

1. **macOS** (tested on modern macOS versions).
2. **Accessibility Permissions**:
   - The app or terminal running the script requires accessibility access to navigate Chrome's UI.
   - Go to **System Settings → Privacy & Security → Accessibility**.
   - Enable your terminal (e.g., **Terminal**, **iTerm**) or the compiled application.

### Windows

1. **Windows 10/11** with **Google Chrome** open.
2. **Windows PowerShell 5.1+** (or PowerShell 7+).
3. **English Chrome UI labels** (`Tab groups`, `Delete group`), since the automation matches those menu item names.

---

## Usage

### Option 1 (macOS): Run via Terminal

1. Open Google Chrome.
2. Run the script:
   ```bash
   osascript delete_saved_tab_groups.applescript
   ```
3. To delete only a specific number of groups (e.g., 10 groups as a test):
   ```bash
   osascript delete_saved_tab_groups.applescript 10
   ```

> [!IMPORTANT]
> Keep your hands off the keyboard and mouse while the script is running, and keep Google Chrome in the foreground. You can interrupt the script at any time by pressing `Ctrl + C` in the Terminal.

---

### Option 2 (Windows): Run via PowerShell

1. Open Google Chrome.
2. In PowerShell, run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\delete_saved_tab_groups_windows.ps1
   ```
3. To delete only a specific number of groups (for example, 10):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\delete_saved_tab_groups_windows.ps1 -MaxToDelete 10
   ```

> [!IMPORTANT]
> Keep Chrome in the foreground while it runs and avoid keyboard/mouse interaction. Stop at any time with `Ctrl + C`.

---

### Option 3 (macOS): Compile to a Standalone App

You can compile the script into a clickable `.app` bundle:

```bash
chmod +x build.sh
./build.sh
```

This generates `Delete Saved Chrome Tab Groups.app`. Double-click to run it anytime.

---

## Files

- `delete_saved_tab_groups.applescript`: The main automation script that drives Chrome menu navigation and deletion.
- `delete_saved_tab_groups_windows.ps1`: Windows automation script using UI Automation to drive the same Chrome menu flow.
- `inspect_chrome_ui.applescript`: A read-only diagnostic tool that prints Chrome's accessibility UI tree.
- `build.sh`: Shell script to package the AppleScript into a `.app` bundle using `osacompile`.

## License

[MIT](LICENSE)
