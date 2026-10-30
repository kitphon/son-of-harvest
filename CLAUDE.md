@AGENTS.md

## Claude Code specifics
- Shell commands run from another working directory, so use absolute paths
  (`/d/Harvest-son/...` in Bash) or `cd /d/Harvest-son && ...` in one command.
- Run the Godot console binary for headless runs and screenshots. Read the last PNG frame
  with the Read tool to check the picture, then delete `shots/`.
- Long runs (exports, many frames) go in the background.
