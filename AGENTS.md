# Agent guidance

## Project

NovaAeris is a public Minecraft server configuration and content repository for a Paper 1.21.4 server. Anyone should be able to review and propose changes through pull requests, including changes to quests, mobs, skills, spells, and other gameplay content. The files present locally are from a test server used to try features; this repository is not intended to record the state of the production server.

## Making changes

- Before editing a setting, inspect the surrounding configuration and identify which server or plugin owns it. Preserve the existing format, comments, and unrelated values.
- Check the installed plugin JAR name/version and any local documentation or examples before changing plugin-specific settings. Do not assume settings from a different plugin release apply.
- Keep changes focused on the requested behavior. Do not upgrade, replace, or download server/plugin JARs unless explicitly requested.
- Do not expose or copy credentials, tokens, private player data, or secret files into documentation, logs, or generated output. Treat `plugins/Denizen/secrets.secret` and database/player data as sensitive.
- Treat world folders, plugin databases, player/user data, backups, and logs as test-server runtime state, not shareable project content. Do not delete, regenerate, reset, or bulk-rewrite them as part of routine config work.
- Prefer tracking intentional, portable configuration and gameplay definitions that describe NovaAeris features. Do not commit incidental state captured from the test server, such as generated player records or server-specific snapshots, unless it is deliberately curated as shareable content.
- Avoid editing generated or machine-specific files unless the task specifically calls for it. Check `.gitignore` and `git status` before deciding what belongs in a change. If an ignored local file contains intentional content that should be shared, separate that content from generated state before proposing it for tracking.
- Do not change security or access controls (such as online mode, whitelist, permissions, operator lists, or RCON settings) unless the request requires it.

## Validation

- This repository has no evident build or automated test workflow. Do not invent one for configuration-only changes.
- For YAML edits, check indentation and ensure the edited section remains structurally consistent. If an appropriate YAML parser is already available, it can be used to parse the changed file; do not install dependencies just for this check.
- Review the final diff and confirm it contains only the intended configuration/documentation changes. Never restart or otherwise operate the live server unless explicitly asked.

## Repository map

- `server.properties`, `bukkit.yml`, `spigot.yml`, `commands.yml`, and `config/` hold server configuration.
- `plugins/<Plugin>/` holds plugin configuration, gameplay content, and runtime data. Distinguish portable project configuration/content from incidental test-server data before editing or proposing files for tracking.
- `world/`, `world_nether/`, and `world_the_end/` hold world state and must be preserved.
- `plugins/*.jar` and the root Paper JAR are installed software, not source code.
