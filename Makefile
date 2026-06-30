INSTALL_DIR = $(HOME)/.local/bin
SCRIPT_NAME = drive-sync
SOURCE_DIR = $(shell pwd)

.PHONY: install uninstall

install:
	mkdir -p $(INSTALL_DIR)
	echo '#!/bin/bash' > $(INSTALL_DIR)/$(SCRIPT_NAME)
	echo 'export DRIVE_SYNC_HOME="$(SOURCE_DIR)"' >> $(INSTALL_DIR)/$(SCRIPT_NAME)
	echo 'exec "$(SOURCE_DIR)/drive_sync.sh" "$$@"' >> $(INSTALL_DIR)/$(SCRIPT_NAME)
	chmod +x $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "✅ Installed to $(INSTALL_DIR)/$(SCRIPT_NAME)"
	@echo ""
	@echo "Make sure $(INSTALL_DIR) is in your PATH."
	@echo "Add this to your ~/.bashrc or ~/.zshrc if not already:"
	@echo "  export PATH=\"\$$PATH:$(INSTALL_DIR)\""

uninstall:
	rm -f $(INSTALL_DIR)/$(SCRIPT_NAME)
	@echo "✅ Removed $(INSTALL_DIR)/$(SCRIPT_NAME)"
	@echo ""
	@echo "Optionally remove $(INSTALL_DIR) from your PATH in:"
	@echo "  ~/.bashrc, ~/.zshrc, or ~/.profile"
