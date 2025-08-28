# dotnvim Makefile
# Provides targets for documentation generation and development tasks

.PHONY: help docs docs-local docs-clean install test

# Default target
help:
	@echo "Available targets:"
	@echo "  docs       - Generate documentation (requires neorg)"
	@echo "  docs-local - Generate documentation for local development"
	@echo "  docs-clean - Clean generated documentation"
	@echo "  install    - Install development dependencies"
	@echo "  test       - Run plugin tests"

# Generate documentation using neorg export
docs:
	@echo "Generating documentation from .norg files..."
	@mkdir -p docs/generated
	@BATCH_EXPORT=1 nvim --headless -u docgen/minimal_init.lua -c 'qa!'
	@echo "Documentation generated in docs/generated/"

# Generate documentation for local development
docs-local: 
	@echo "Generating documentation locally..."
	@mkdir -p docs/generated
	@if ! command -v nvim >/dev/null 2>&1; then \
		echo "Error: neovim is not installed"; \
		exit 1; \
	fi
	@# Clone neorg locally if it doesn't exist
	@if [ ! -d "neorg" ]; then \
		echo "Cloning neorg..."; \
		git clone --depth=1 https://github.com/nvim-neorg/neorg.git neorg; \
	fi
	@NEORG_PATH=./neorg BATCH_EXPORT=1 nvim --headless -u docgen/minimal_init.lua -c 'qa!'
	@echo "Documentation generated in docs/generated/"

# Clean generated documentation
docs-clean:
	@echo "Cleaning generated documentation..."
	@rm -rf docs/generated/
	@rm -rf neorg/
	@echo "Documentation cleaned."

# Install development dependencies
install:
	@echo "Installing development dependencies..."
	@if command -v luarocks >/dev/null 2>&1; then \
		luarocks install --local plenary.nvim; \
	else \
		echo "Warning: luarocks not found, skipping lua dependencies"; \
	fi
	@echo "Dependencies installed."

# Run plugin tests (if test framework is set up)
test:
	@echo "Running plugin tests..."
	@if [ -d "tests" ]; then \
		echo "Running tests with plenary..."; \
		nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"; \
	else \
		echo "No tests directory found."; \
	fi