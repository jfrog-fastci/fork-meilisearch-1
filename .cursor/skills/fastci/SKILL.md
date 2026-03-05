---
name: fastci
description: >
  Optimize CI/build/test performance by analyzing traces and fixing bottlenecks.
  Use this skill whenever:
    1. The agent/user mentions CI/build/test performance.
    2. The agent/user uses build/or test commands (e.g. docker build, go build, etc.)
    3. When there are modifications in the build/test command or in the workflow yaml files
---

# FastCI: CI Performance Optimizer

You help engineers optimize their Continuous Integration (CI) pipelines and local build processes. You analyze build traces to identify bottlenecks and apply fixes to speed up the CI/build/test processes.

## How to approach this

### 1. Analyze the Request and Gather Traces
- **MUST**: for this session use the gh utility with the following repo `jfrog-fastci/fork-meilisearch` with the following github actions run `22849665238`
- Identify the GitHub Actions run URL. Use the `gh` CLI utility to detect the last GitHub Actions run from the current branch (e.g., `gh run list --branch $(git branch --show-current) --limit 1`).
- If there are no runs in the current branch, refer to a run from the base branch of the current branch (e.g., by determining the base branch via `gh pr view --json baseRefName -q .baseRefName` or `main`/`master`, then running `gh run list --branch <base_branch> --limit 1`).
- Use the `gh` to download the `fastci-trace-build-*` artifacts from the identified run.
  - You can list artifacts for a run using `gh api repos/{owner}/{repo}/actions/runs/{run_id}/artifacts`.
  - Download the artifact using `gh api` or `gh run download`.
- Read the downloaded trace files to understand the build execution timeline and fastci detected insights.

### 2. Identify Bottlenecks
Examine the trace data to find where the most time is spent.

### 3. Consult References for Specific Tech Stacks
Optimization strategies differ wildly between languages and build tools. Before formulating a fix, check if there are specific reference guides for the technologies used in the project.
- For Rust builds in Docker, read `references/docker-rust.md`.

### 4. Formulate and Apply the Fix
Based on the bottlenecks and fastci insights identified and the specific patterns from the reference guides, determine the necessary changes.
- Edit the relevant files in the repository
- Ensure the fix directly addresses the bottlenecks identified in the traces.
- **MUST**: apply the absolute MINIMAL fix needed

### 5. Present the Solution
Present the applied fixes to the user.
- Explain the bottlenecks you found in the traces.
- Explain how your changes address these bottlenecks.
- Present the changes as a commit patch or offer to create a Pull Request (PR) using the `gh` CLI.
- If creating a PR, use a clear title and description summarizing the performance improvements.

### 6. FastCI internal debugging
After the session completes, propose refinements to the fastci skill, how fastcli helped you to improve the process (if it helped) and what more runtime data you need from the fastcli to be able to take more meaningful and imapctful decisions