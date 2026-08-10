# Indiedown with OpenSpec & GitHub Copilot

This repository uses **OpenSpec** for structured change management and integrates with **GitHub Copilot** for intelligent code assistance.

## OpenSpec Workflows

OpenSpec provides four core workflows for managing changes:

### 1. **Propose** (`/opsx:propose`)
Create a comprehensive proposal for a new change including:
- **proposal.md** - What you want to build and why
- **design.md** - Architecture and design decisions
- **tasks.md** - Implementation steps and checklist

**Usage:**
```bash
/opsx:propose "add user authentication"
```

### 2. **Apply** (`/opsx:apply`)
Implement a proposed change by:
- Reading all proposal artifacts
- Creating/modifying code files
- Running tests to verify the implementation
- Creating a commit with all changes

**Usage:**
```bash
/opsx:apply
```

### 3. **Explore** (`/opsx:explore`)
Understand the codebase by:
- Analyzing project structure
- Reading key files and dependencies
- Understanding existing patterns and conventions
- Generating context for new changes

**Usage:**
```bash
/opsx:explore "authentication module"
```

### 4. **Archive** (`/opsx:archive`)
Complete a change by:
- Documenting final decisions
- Creating implementation notes
- Archiving the change directory
- Preparing for cleanup

**Usage:**
```bash
/opsx:archive
```

## GitHub Copilot Integration

GitHub Copilot is enabled for intelligent assistance with:

- **Code Reviews** - Automated review suggestions and quality checks
- **Issue Resolution** - Help fixing bugs and implementing features
- **Pull Requests** - Assistance with PR creation and descriptions
- **Commit Suggestions** - Smart commit message generation

### Using Copilot with OpenSpec

When proposing changes, Copilot helps with:
1. Design analysis and architecture suggestions
2. Code generation during apply workflow
3. Test case generation
4. Documentation and comments

## Project Structure

```
.
├── .claude/
│   ├── settings.json           # OpenSpec & Copilot configuration
│   ├── commands/opsx/          # OpenSpec command definitions
│   │   ├── propose.md
│   │   ├── apply.md
│   │   ├── explore.md
│   │   └── archive.md
│   └── skills/                 # OpenSpec workflow implementations
│       ├── openspec-propose/
│       ├── openspec-apply-change/
│       ├── openspec-explore/
│       └── openspec-archive-change/
└── openspec/
    ├── changes/                # Proposed changes
    │   └── <change-name>/
    │       ├── proposal.md
    │       ├── design.md
    │       ├── tasks.md
    │       └── .openspec.yaml
    └── schema/                 # OpenSpec schema and rules
```

## Getting Started

### Step 1: Explore the Codebase
```bash
/opsx:explore
```

### Step 2: Propose a Change
```bash
/opsx:propose "describe what you want to build"
```

### Step 3: Review the Artifacts
Review the generated proposal, design, and tasks in `openspec/changes/<change-name>/`

### Step 4: Apply the Change
```bash
/opsx:apply
```

### Step 5: Archive When Complete
```bash
/opsx:archive
```

## Configuration

The OpenSpec and Copilot configuration is in `.claude/settings.json`:

- **OpenSpec Workflows** - All four workflows are enabled
- **GitHub Copilot Features** - Code review, issues, PRs, and commits enabled
- **Auto-behaviors** - Optional auto-assignment and auto-review (currently disabled)
- **AI Model** - Uses Claude Opus 4.7 by default

## Tips & Best Practices

1. **Always start with Explore** to understand context before proposing changes
2. **Be descriptive in proposals** - More detail leads to better designs
3. **Review artifacts** before applying - Ensure the design meets your needs
4. **Use GitHub Copilot** for code review suggestions on your PRs
5. **Archive changes** to keep the openspec directory clean

## Documentation

For more information:
- OpenSpec: https://github.com/Fission-AI/OpenSpec
- GitHub Copilot: https://github.com/features/copilot
- Claude Code: https://claude.ai/code
