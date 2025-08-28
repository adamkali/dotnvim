# Documentation System

This directory contains the documentation source files for dotnvim, written in Neorg (.norg) format.

## Structure

- `index.norg` - Main documentation homepage
- `installation.norg` - Installation and setup guide
- `configuration.norg` - Configuration options and examples
- Additional .norg files for specific topics

## Local Generation

To generate documentation locally:

```bash
make docs-local
```

This will:
1. Clone the neorg plugin if needed
2. Convert all .norg files to markdown
3. Output to `docs/generated/`

## Automation

Documentation is automatically generated and deployed when:
- Changes are pushed to the `main` branch
- Changes are made to files in `docs/norg/`
- The workflow is manually triggered

The generated documentation is available at: `https://adamkali.github.io/dotnvim/`

## Writing Documentation

When adding new .norg files:

1. Include proper document metadata:
   ```norg
   @document.meta
   title: Your Title
   description: Brief description
   authors: adamkali
   categories: relevant categories
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   version: 1.0.0
   @end
   ```

2. Use proper Neorg syntax for headers, links, and code blocks
3. Reference other documentation pages using `{/ filename}` syntax
4. Test locally with `make docs-local` before committing