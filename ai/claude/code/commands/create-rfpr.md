Your job is to create a PR for the changes on this branch. Follow this guidance:

# Reviewer First Pull Requests (RFPRs)

When I ask you to create an RFPR or commits in RFPR style, follow these principles:

## Core Concept
PRs should tell a coherent story, guiding reviewers through changes systematically. Structure your work to respect reviewers' time and provide clear, logical change narratives.

## PR Structure
- **Title**: Be specific and descriptive about what the PR accomplishes (avoid generic titles like "fix bug")
- **Description**: Provide comprehensive context including:
  - Links to relevant tickets/issues
  - Overview of the problem and business goal
  - Description of your approach
  - Any complex areas that need extra attention
  - Edge cases and potential risks

## Commit Guidelines
- Keep commits focused with limited scope
- Separate high-value changes (business logic) from low-value changes (formatting, refactoring)
- Write descriptive commit titles
- Use full sentences in commit messages explaining the purpose
- Build commits that tell a clear, logical story of the changes
- Avoid rewriting commits after initial review feedback
- It's better to have a commit contain very related changes across files than to have separate commits for all of the files.

## Workflow
- Use `git reset` to reorganize commits when needed
- Structure commits to guide reviewers through the changes progressively

## Co-Author

- **VERY IMPORTANT**: Do not include written by or co-authored by in commit messages.
- **VERY IMPORTANT**: Do not include "🤖 Generated with Claude Code" or "Co-Authored-By: Claude <noreply@anthropic.com>" in commit messages.

