# delete-chrome-tab-groups

A macOS automation tool to bulk-delete saved tab groups from Google Chrome's **⋮ > Tab groups** menu.

## Background & Why This Exists

In Google Chrome, saved tab groups are synced across your devices via your Google Account. 
- Chrome Extension APIs (`chrome.tabGroups`, `chrome.tabs`) **only** have access to active, open tab groups in the current window. They cannot access, query, or delete saved tab groups that are closed.
- Manually deleting hundreds of saved tab groups through the Chrome menu one-by-one is tedious and time-consuming.

This tool automates Chrome's native UI navigation on macOS to cleanly and permanently delete all closed saved tab groups in bulk.

> [!NOTE]
> **Safety:** The script only deletes tab groups with the status **"Closed"**. Tab groups that are currently open in your browser are left untouched to prevent accidentally closing your active tabs.

---

## Prerequisites

1. **macOS** (tested on modern macOS versions).
2. **Accessibility Permissions**:
   - The app or terminal running the script requires accessibility access to navigate Chrome's UI.
   - Go to **System Settings → Privacy & Security → Accessibility**.
   - Enable your terminal (e.g., **Terminal**, **iTerm**) or the compiled application.

---

## Usage

### Option 1: Run via Terminal (Recommended)

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

### Option 2: Compile to a Standalone macOS App

You can compile the script into a clickable `.app` bundle:

```bash
chmod +x build.sh
./build.sh
```

This generates `Delete Saved Chrome Tab Groups.app`. Double-click to run it anytime.

---

## Files

- `delete_saved_tab_groups.applescript`: The main automation script that drives Chrome menu navigation and deletion.
- `inspect_chrome_ui.applescript`: A read-only diagnostic tool that prints Chrome's accessibility UI tree.
- `build.sh`: Shell script to package the AppleScript into a `.app` bundle using `osacompile`.

## License

[MIT](LICENSE)
