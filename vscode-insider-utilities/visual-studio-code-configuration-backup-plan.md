# Final Plan: VS Code Insiders Backup & Restore

This plan outlines a minimal, clean, and complete strategy to back up your essential VS Code Insiders user configuration.

### 1. What to Back Up

The strategy is to back up the entire `User` directory while excluding temporary caches, state files, and other auto-generated content. This ensures that all your personal configurations are saved.

**Essential Items to be Backed Up:**

*   `$HOME/Library/Application Support/Code - Insiders/User/settings.json`: Your global user settings.
*   `$HOME/Library/Application Support/Code - Insiders/User/profiles/`: All 13+ of your profiles, including their individual settings, extension lists, and tasks.
*   `$HOME/Library/Application Support/Code - Insiders/User/keybindings.json`: Your global keyboard shortcuts (if it exists).
*   `$HOME/Library/Application Support/Code - Insiders/User/snippets/`: Your global code snippets (if it exists).
*   `$HOME/Library/Application Support/Code - Insiders/User/mcp.json`: Your Model Context Protocol (AI provider) configurations.
*   `$HOME/Library/Application Support/Code - Insiders/User/tasks.json`: Your global tasks (if it exists).

**Items to be Excluded (and Why):**

*   `mcp/`: Contains auto-downloaded AI provider binaries, not user configuration.
*   `globalStorage/` & `workspaceStorage/`: Caches for extensions and workspaces. VS Code rebuilds these automatically. The `--exclude` flag correctly removes these from both the root `User` folder and from within each profile's folder.
*   `state.vscdb`, `CachedData`, `Backups`, `sync/`: Session state, caches, crash recovery, and built-in sync data. All are transient or managed elsewhere.

### 2. The Backup Command

This `rclone` command efficiently performs the backup on macOS.

```bash
# Define source and destination
VSCODE_USER_CONFIG="$HOME/Library/Application Support/Code - Insiders/User/"
BACKUP_DEST="$HOME/Lab_Data/configurations-private/vscode-insiders-configuration-backup"

# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DEST"

# Run the backup
rclone sync "$VSCODE_USER_CONFIG" "$BACKUP_DEST/" --create-empty-src-dirs \
  --exclude="mcp/**" \
  --exclude="globalStorage/**" \
  --exclude="workspaceStorage/**" \
  --exclude="state.vscdb" \
  --exclude="CachedData/**" \
  --exclude="Backups/**" \
  --exclude="sync/**"
```

* rclone sync: This command makes the destination identical to the source, deleting any files from the backup that are no longer in your live configuration.
* --create-empty-src-dirs: This ensures that if you have empty folders you want to keep (like an empty snippets directory), they are preserved in the backup.

### 3. The Restore Process

Restoring your configuration on a new or wiped machine is just as straightforward.

**Step 1: Stop VS Code Insiders**
Ensure the application is fully closed to prevent file conflicts.
```bash
pkill -f "Code - Insiders"
```

**Step 2: Restore the Files**
Use `rclone` to copy your backed-up configuration back into place.
```bash
# Define your source and destination
VSCODE_USER_CONFIG="$HOME/Library/Application Support/Code - Insiders/User/"
BACKUP_DEST="/Users/dk/Lab_Data/configurations-private/vscode-insiders-configuration-backup"

# Run the restore
rclone copy "$BACKUP_DEST/" "$VSCODE_USER_CONFIG"
```

**Step 3: Relaunch VS Code Insiders**
```bash
open -a "Visual Studio Code - Insiders"
```
On the first launch, VS Code will read the `extensions.json` file in each of your restored profiles and automatically begin reinstalling all the necessary extensions. This may take a few minutes, after which your environment will be fully restored.
