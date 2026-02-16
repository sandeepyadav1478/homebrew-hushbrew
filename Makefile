.PHONY: lint install uninstall help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

lint: ## Run shellcheck on all scripts
	shellcheck bin/hushbrew.sh
	shellcheck bin/brew-curl
	shellcheck install.sh
	shellcheck uninstall.sh
	@echo "All scripts passed shellcheck."

install: ## Install hushbrew on this Mac
	@./install.sh

uninstall: ## Uninstall hushbrew from this Mac
	@./uninstall.sh
