# Drive Sync

A robust command-line tool for synchronizing and optimizing PDF files with Google Drive.

## Features

- **Two-way sync** between local and Google Drive
- **Automatic PDF compression** using Ghostscript
- **Rate limit handling** with automatic recovery
- **File locking** for concurrent run safety
- **Structured logging** with rotation
- **Storage usage display** in binary units (GiB, MiB, KiB)
- **9 modular components** for maintainability

## Installation

### Prerequisites

- [rclone](https://rclone.org/) configured with Google Drive
- [Ghostscript](https://ghostscript.com/) for PDF compression
- Bash 4.0+ or Zsh
- Optional: `bc` for precise calculations, `jq` for JSON parsing

### Quick Install

```bash
git clone https://github.com/yourusername/drive-sync.git
cd drive-sync
./drive-sync.sh setup
```

### Manual Setup

1. Clone the repository
2. Make scripts executable: `chmod +x drive-sync.sh lib/*.sh`
3. Configure rclone: `rclone config`
4. Set up remote name in `config/settings.conf`

## Usage

### Basic Commands

```bash
./drive-sync.sh sync          # Sync and compress PDFs
./drive-sync.sh status        # Show current status
./drive-sync.sh ratelimit     # Manual rate limit recovery
./drive-sync.sh logs          # View logs
./drive-sync.sh help          # Show help
```

### Sync Process

1. **Scan**: Finds all PDFs in the local directory
2. **Compress**: Uses Ghostscript to optimize PDFs
   - Files under 10KB are marked as optimized
   - Files that don't compress are renamed with `.optimized.pdf`
   - Failed compressions are preserved for retry
3. **Sync**: Uploads compressed files to Google Drive
4. **Monitor**: Handles rate limits automatically

### Status Display

The `status` command shows:
- Total PDF count and breakdown (optimized/pending)
- Storage usage in binary units (GiB/MiB/KiB)
- Last sync and compression timestamps
- Sync status and rate limit recovery count

## Configuration

Edit `config/settings.conf`:

```bash
# Remote configuration
remote_name="gdrive"
local_path="/path/to/documents"

# PDF optimization
optimized_marker=".optimized"
gs_device="pdfwrite"
min_valid_size=1024  # bytes

# Rate limiting
rate_limit_sleep=60  # seconds
max_rate_limit_retries=10

# Logging
log_dir="./logs"
log_retention_days=30
```

## Architecture

The tool consists of 9 modular components:

1. **`drive-sync.sh`** - Main entry point
2. **`lib/cli.sh`** - Command-line interface and formatting
3. **`lib/sync.sh`** - Core sync logic
4. **`lib/compression.sh`** - PDF compression with binary size formatting
5. **`lib/storage.sh`** - Storage quota display (binary units)
6. **`lib/ratelimit.sh`** - Rate limit handling
7. **`lib/logging.sh`** - Logging with rotation
8. **`lib/lock.sh`** - File locking for concurrent runs
9. **`lib/utils.sh`** - Utility functions including decimal formatting

## Size Formatting

The tool now displays storage sizes in **binary units** (GiB, MiB, KiB) to match common file system conventions, while maintaining compatibility with Google Drive's decimal display where needed.

## Logging

Logs are stored in `./logs/` with:
- Automatic rotation
- Timestamped entries
- Success/error/warning levels
- Compression metrics (percentage reduction, space saved)

## Rate Limit Handling

When Google Drive rate limits are encountered:
1. Tool pauses execution
2. Waits for recovery period
3. Resumes automatically
4. Tracks recovery attempts in logs

## Troubleshooting

### Common Issues

**"rclone not found"**
- Install rclone: `curl https://rclone.org/install.sh | sudo bash`

**"gs not found"**
- Install Ghostscript: `sudo apt install ghostscript` (Ubuntu/Debian) or `brew install ghostscript` (macOS)

**Permission denied**
- Make scripts executable: `chmod +x drive-sync.sh lib/*.sh`

**"bc not found"**
- Install bc: `sudo apt install bc` (Ubuntu/Debian) or `brew install bc` (macOS)

### Manual Rate Limit Recovery

```bash
./drive-sync.sh ratelimit
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following existing style
4. Test thoroughly
5. Submit a pull request

## License

Drive Sync is distributed freely under the [MIT License](https://opensource.org/licenses/MIT). See `LICENSE` for details.

## Acknowledgments

- [rclone](https://rclone.org/) for Google Drive integration
- [Ghostscript](https://ghostscript.com/) for PDF compression
- All contributors and users
