# AI Agent Guidelines

## Overview

This document provides guidelines and best practices for AI agents working
on this repository. Follow these standards to ensure consistency, quality,
and maintainability across all contributions.

## Table of Contents

- [AI Agent Guidelines](#ai-agent-guidelines)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Markdown Files](#markdown-files)
    - [Linting and Formatting](#linting-and-formatting)
    - [Markdown Best Practices](#markdown-best-practices)
  - [Version Control](#version-control)
    - [Commit Messages](#commit-messages)
      - [Format Rules](#format-rules)
      - [Commit Message Structure](#commit-message-structure)
        - [Example](#example)
    - [Branching](#branching)
    - [Pull Requests](#pull-requests)
  - [Quality \& Best Practices](#quality--best-practices)

## Markdown Files

### Linting and Formatting

- **Markdown compliance**: Ensure all Markdown files pass `rumdl` checks
- **Code blocks**: For `bash`/`shell` code blocks:
  - Verify they pass `shellcheck` validation
  - Format with `shfmt` for consistency

### Markdown Best Practices

- Use proper heading hierarchy (don't skip levels)
- Wrap lines at 80 characters for readability
- Use semantic HTML only when necessary
- Prefer code fences over inline code for multi-line examples
- Include language identifiers in code fences

## Version Control

### Commit Messages

#### Format Rules

- **Conventional commit format**: Use standard types (`feat`, `fix`, `docs`,
  `chore`, `refactor`, `test`, `style`, `perf`, `ci`, `build`, `revert`)
- **Line limits**: Subject ≤ 80 characters, body lines ≤ 80 characters
- **Single blank line**: Between subject and body, between body paragraphs

#### Commit Message Structure

- **Subject line**:
  - Imperative mood (e.g., "add" not "added" or "adds")
  - Use lower case (except for proper nouns and abbreviations)
  - No period at the end
  - Maximum 80 characters
  - Format: `<type>: <description>`

- **Body** (optional but recommended for non-trivial changes):
  - Explain **what** changed and **why**
  - Wrap lines at 80 characters
  - Use Markdown formatting
  - Separate paragraphs with blank lines
  - Reference issues using keywords: `Fixes`, `Closes`, `Resolves`

##### Example

```markdown
feat: add automated dependency updates

- Implement Dependabot configuration
- Configure weekly security updates
- Add auto-merge for patch/minor updates

Resolves: #123
```

### Branching

- **Naming convention**: Follow the
  [Conventional Branch](https://conventional-branch.github.io/)
  specification

- **Naming guidelines**:
  - Keep branch names concise and descriptive
  - Use kebab-case (lower case with hyphens)
  - Include issue number when applicable: `feat/123-add-feature-name`

### Pull Requests

- **Always create draft PR** - Create pull requests as drafts initially
- **Title format** - Use conventional commit format (`feat: add new feature`)
- **Description** - Include clear explanation of changes and motivation
- **Link issues** - Reference related issues using keywords (Fixes, Closes,
  Resolves)

## Quality & Best Practices

- Pass pre-commit hooks
- Follow project coding standards
- Include tests for new functionality
- Update documentation for user-facing changes
- Make atomic, focused commits
- Explain reasoning behind changes
- Maintain consistent formatting
