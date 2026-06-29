# Drive Sync

**Safe, modular Google Drive synchronization with optional PDF compression.**

---

## What It Does

**Drive Sync** keeps a local folder (`~/drive`) in sync with Google Drive while compressing PDFs before upload when it makes sense. It's built around one core principle: **your original files are never lost**.

---

## How Compression Works

**Philosophy**: Better to upload uncompressed than to upload corrupted.

When you run `push` or `sync`, the tool looks at each PDF:

### Case 1: File is already small (< 10 KB)
- Skips compression (would be a waste of time)
- **Renames** to `file.optimized.pdf`
- Message: "Marked as optimized (already small)"

### Case 2: Compression works and reduces size
- Deletes the original
- Saves compressed version as `file.optimized.pdf`
- Message: "Optimized: 35% reduction (saved 2.3 MB)"

### Case 3: Compression works but doesn't reduce size
- **Renames** the original to `file.optimized.pdf`
- Message: "Marked as optimized (already at optimal size)"

### Case 4: Compression fails
- **Preserves the original** (doesn't touch it)
- Logs the error
- Message: "Keeping original file intact (will retry next run)"
- Will try again on the next execution

**The `.optimized.pdf` suffix means**: "This PDF is at its optimal size" — whether it was compressed, or was already small enough. You never need to worry about it again.

---

## Safety Guarantees

- **Originals always survive**: If PDF compression fails, the original stays on disk. Sync aborts rather than uploading corrupted compressed PDFs.
- **No remote deletion by default**: `push` only sends new/changed files. Use `pull` to sync *from* Drive, and `sync` for both directions (remote changes overwrite local in conflicts).
- **Atomic state updates**: File locking prevents corruption during concurrent runs.
- **Rate limit recovery**: Detects Google Drive API throttling and waits before retrying.

---

## Installation

### Requirements

- `bash 4+`
- `rclone` — Google Drive sync
- `ghostscript` — PDF compression
- `jq` — JSON state management
- `flock` — File locking (part of `util-linux` on Linux, `coreutils` on macOS)
- `bc` — Optional (falls back to integer arithmetic)

### Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install rclone ghostscript jq bsdutils bc

# macOS
brew install rclone ghostscript jq coreutils
```

### Configure Rclone

```bash
rclone config
# Create a remote named "drive:" pointing to your Google Drive
```

### Install Drive Sync

```bash
# Clone the repository
git clone https://github.com/MiguelMochizukiDev/drive-sync.git
cd drive-sync

# Make the script executable
chmod +x drive_sync.sh

# Install to /usr/local/bin (system-wide)
sudo ln -sf "$(pwd)/drive_sync.sh" /usr/local/bin/drive-sync

# Verify installation
drive-sync --version
```

---

## Usage

### Basic Workflow

```bash
# Check status
drive-sync status

# Download remote changes
drive-sync pull

# Review local changes, then upload (with compression)
drive-sync push

# Or: full sync in one step (pull then push)
drive-sync sync
```

### Commands

| Command | Description |
|---------|-------------|
| `push` | Upload local changes to Google Drive with PDF compression |
| `pull` | Download remote changes to local (no compression) |
| `sync` | Full bidirectional sync (pull then push) |
| `status` | Show sync history, PDF counts, and storage usage |
| `ratelimit` | Manually recover from Google Drive rate limiting |

### Options

| Option | Description |
|--------|-------------|
| `-n, --dry-run` | Preview changes without applying |
| `-f, --force` | Skip confirmation prompts |
| `-h, --help` | Show help |
| `-v, --version` | Show version |

### Command Details

#### `push` — Upload to Drive

Compresses PDFs, then syncs local → Drive.

- Compresses any PDF not yet optimized
- **Aborts if compression fails** (original preserved)
- Failed files are retried on the next run
- Use `-n` to preview without uploading

#### `pull` — Download from Drive

Syncs Drive → local. No compression.

- Downloads new/changed remote files
- **Does not delete local files**
- Safe to run anytime; conflicts favor remote (newer)

#### `sync` — Bidirectional Sync

Pulls first, then pushes.

- Remote changes overwrite local in conflicts
- Useful for initial setup or full reconciliation
- Tip: Use `pull` first to review, then `push` separately

#### `status` — Show State

Displays:
- Last sync/compression timestamps
- Sync status and rate limit recovery count
- PDF counts (optimized vs unoptimized)
- Google Drive storage usage (in decimal GB, matching Drive's display)

#### `ratelimit` — Manual Rate Limit Recovery

Manually trigger recovery from Google Drive rate limiting.

- Waits 5 minutes and tests connection
- Only needed if automatic recovery fails

---

## Directory Structure

```
~/drive/                       # Main sync directory (rclone's local path)
├── .sync/
│   ├── state.json             # Compression/sync history (JSON)
│   └── state.lock             # Lock file for concurrent safety
├── .logs/
│   └── drive_sync.log         # Detailed logs (rotates at 10 MB)
├── document.pdf               # Original or unoptimized file
└── document.optimized.pdf     # Optimized version
```

### State File Schema

```json
{
  "last_sync": "2026-06-29T15:30:00+00:00",
  "last_compression": "2026-06-29T15:29:45+00:00",
  "sync_status": "success" | "failed" | "idle",
  "rate_limit_recoveries": 0,
  "last_rate_limit": "2026-06-29T15:28:00+00:00",
  "total_files_synced": 0,
  "total_bytes_synced": 0
}
```

---

## Common Workflows

### Initial Setup

```bash
# 1. Configure rclone
rclone config

# 2. Pull everything from Drive
drive-sync pull

# 3. Check status
drive-sync status

# 4. Later: sync changes regularly
drive-sync sync
```

### Add New Files Locally

```bash
# Copy files to ~/drive
cp my_files.pdf ~/drive/

# Compress and upload
drive-sync push
```

### Sync Changes from Drive

```bash
# Update local from remote
drive-sync pull

# Review, then sync back if you modified things
drive-sync push
```

### Handle Compression Failures

If some PDFs fail to compress:

```bash
# See which files failed (check logs)
tail -f ~/drive/.logs/drive_sync.log

# Option 1: Retry later - simply run push again
drive-sync push

# Option 2: Delete the problematic file
rm ~/drive/problem.pdf
drive-sync push
```

### Dry-Run Before Sync

```bash
# Preview what will be uploaded/downloaded without making changes
drive-sync sync -n
```

---

## Logging

Logs go to `~/drive/.logs/drive_sync.log` (rotates at 10 MB). Each entry includes timestamp and level (INFO, WARNING, ERROR, SUCCESS).

To tail:

```bash
tail -f ~/drive/.logs/drive_sync.log
```

---

## Architecture

Modular design: each module has one responsibility.

```
lib/
├── cli.sh           # Command-line interface and help
├── compression.sh   # Ghostscript wrapper with safety checks
├── config.sh        # Paths, timeouts, performance tuning
├── limit.sh         # Rate limit detection and recovery
├── logging.sh       # Structured logging with rotation
├── state.sh         # JSON state with file locking
├── storage.sh       # Google Drive storage quota display
├── sync_ops.sh      # Rclone wrapper with standardized flags
└── utils.sh         # Path validation, math, file utilities
```

### Module Dependencies

```
cli.sh        → config.sh, state.sh, storage.sh, logging.sh
compression.sh → config.sh, utils.sh, logging.sh, state.sh
limit.sh      → config.sh, state.sh, logging.sh
storage.sh    → config.sh, utils.sh, logging.sh
sync_ops.sh   → config.sh, logging.sh, limit.sh
state.sh      → config.sh, logging.sh
drive_sync.sh → All modules
```

---

## Performance Tuning

Edit `lib/config.sh` to adjust:

| Variable | Default | Description |
|----------|---------|-------------|
| `RCLONE_TRANSFERS` | 2 | Parallel uploads |
| `RCLONE_CHECKERS` | 2 | Parallel file checks |
| `RCLONE_TPSLIMIT` | 8 | API calls per second |
| `RCLONE_DRIVE_CHUNK_SIZE` | 128M | Upload chunk size |
| `GHOSTSCRIPT_DEVICE` | pdfwrite | Compression profile |
| `RATE_LIMIT_BACKOFF_SECONDS` | 300 | Wait time after rate limit |
| `MAX_RETRIES` | 3 | Sync attempts before giving up |

---

## Troubleshooting

### "Rclone remote 'drive:' not configured"

Run `rclone config` and create a remote named `drive:` pointing to Google Drive.

### "Missing dependencies: gs"

Install Ghostscript:

```bash
# Ubuntu/Debian
sudo apt-get install ghostscript

# macOS
brew install ghostscript
```

### Rate Limit Errors

Google Drive rate-limits heavy sync. The tool detects (error code 7 or 9) and retries after 5 minutes. If manual recovery is needed:

```bash
drive-sync ratelimit
```

### Compression Failing on Specific PDFs

Some PDFs may be damaged or use unsupported features. Options:

1. **Retry later** (Ghostscript config may have changed):
   ```bash
   drive-sync push
   ```

2. **Delete the file**:
   ```bash
   rm ~/drive/problem.pdf
   drive-sync push
   ```

### Concurrent Runs

File locking prevents corruption. Only one instance can sync at a time; others wait up to 10 seconds for the lock.

### Log Files

Check the log for detailed error messages:

```bash
tail -f ~/drive/.logs/drive_sync.log
```

---

## Security

### Path Validation

Drive Sync validates all file operations to ensure they stay within `~/drive`. This prevents accidental modification of system directories due to bugs or misconfiguration.

### File Locking

State updates use `flock` with a 10-second timeout, preventing corruption from concurrent runs.

### No Root Required

All operations run with user permissions. No `sudo` required for normal operation.

---

## Contributing

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/drive-sync.git
cd drive-sync

# Make scripts executable
chmod +x drive_sync.sh

# Run tests (if available)
./test.sh
```

### Adding a New Feature

1. Create a new module in `lib/`
2. Source it in `drive_sync.sh`
3. Add tests (if test suite exists)
4. Update README with documentation
5. Submit a pull request

### Code Style

- Use `set -euo pipefail` in all scripts
- Follow existing naming conventions
- Add comments for complex logic
- Use `local` for all function variables
- Log all significant operations

---

## License

Drive Sync is distributed freely under the [MIT License](https://opensource.org/license/mit).

---

## Version History

### 1.0.0 (June 2026)

- Initial stable release
- Core sync functionality (push, pull, sync)
- PDF compression with Ghostscript
- **Smart optimization logic**:
  - Files that compress successfully and reduce size become `.optimized.pdf`
  - Files that are already small (< 10 KB) are renamed to `.optimized.pdf`
  - Files that compression doesn't reduce are renamed to `.optimized.pdf`
  - Files that fail compression are preserved and retried later
- Rate limit recovery
- Storage usage display (decimal units matching Google Drive)
- Concurrent run safety with file locking
- Structured logging with automatic rotation
- 9 modular components
- No marker files — `.optimized.pdf` suffix indicates optimal size

---

## Credits

- [Rclone](https://rclone.org/) — File sync engine
- [Ghostscript](https://www.ghostscript.com/) — PDF compression
- [jq](https://stedolan.github.io/jq/) — JSON processing

---

## Support

For issues and feature requests, please use the [issue tracker](https://github.com/MiguelMochizukiDev/drive-sync/issues).

For questions and discussion, use [GitHub Discussions](https://github.com/MiguelMochizukiDev/drive-sync/discussions).
