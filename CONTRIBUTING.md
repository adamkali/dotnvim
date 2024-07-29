
# Contributing to `dotnvim`

We welcome contributions to `dotnvim`! Whether you're fixing bugs, adding new features, or improving documentation, your help is appreciated.

## How to Contribute

### 1. Fork the Repository

Fork the [repository](https://github.com/adamkali/dotnvim.git) 

### 2. Clone the Fork

Clone your forked repository to your local machine:

```bash
git clone https://github.com/adamkali/dotnvim.git
```

### 3. Create a Branch

Create a new branch for your work. Use a descriptive name for the branch to make it clear what your changes are about. Please use semantic branch names to categorize your work, such as:
- `feat/feature-name` for new features
- `bug/bug-fix-description` for bug fixes
- `infra/infrastructure-change` for infrastructure or configuration changes
- `docs/documentation-update` for documentation changes

**e.g. <type>/<fork name>/<optional issue name>**

Example:

```bash
git checkout -b feat/new-authentication-system
```

types:
```
[
  'build',
  'docs',
  'feat',
  'fix',
  'perf',
  'refactor',
  'infra',
  'style'
];
```

### 4. Make Your Changes

Make the necessary changes to the codebase. Ensure your code follows the project's coding standards and includes appropriate documentation.

### 5. Commit Your Changes

Once you've made your changes, commit them with a clear and concise commit message:

```bash
git add .
git commit -m "Brief description of your changes"
```

Realistically, keep your pull requests to keep to a somewhat [unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) for pull requests.
- 1. Make each pull request do one thing. (i.e. the semantic branch name)
- 2. Anyone looking at the pull request should expect what the change is doing, and be able to verify that the changes are what is expected.
- 3. Any pull request should be able to be thrown away easily, ie Modular revisions.
- 4. The commits in the pull request should read as a change log. If anyone who has not worked on the project were to look at your "change log" they should be able to get up to speed. Anyone who is doing code review should be able to explain based on your "change log" where and what commits are making the pull request rejected.

### 6. Push Your Changes

Push your changes to your forked repository:

```bash
git push origin feat/new-authentication-system
```

### 7. Create a Pull Request

Go to the original repository on GitHub and create a pull request from your branch. Provide a clear description of what your changes do and why they are needed.

## Style Guide

use the lua formatter.

## Reporting Issues

If you find any bugs or have suggestions for improvements, please open an issue in the [issue tracker](link-to-issue-tracker).

## License

By contributing to this repository, you agree that your contributions will be licensed under the [MIT License](https://opensource.org/license/MIT).

