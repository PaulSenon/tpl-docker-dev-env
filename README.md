# Docker Dev Environment

This is a template repo I use to start any project.
It setup a nodejs containerized environment, that reuse some of you host setup and that you can personalize.

This might be refined quite a lot, the state of this template is meant to improve over time.

## Goal

So you can collaborate, cross OS/Arch, team-wide, with one command install the full dev environement.
And because everything is containerized, Agentic dev tools are bound to your project.

## Features

- customize `.bashrc` *(in ./docker/dev/settings/.bashrc)*
- auto loads your `~/.gitconfig` from host (so you keep your git user config and aliases)
- preinstalled codex/claude-code/open-code and auto loads all your host configs for them
- containerize by design the access of LLMs coding agents to your project files only (no access to host files)
- basic agent config
- dev container bash history is saved between sessions
- preconfigured mcp for opencode (just add your secrets in .env.llms.local)

## Installation

This is meant to be the first setup install. Not the install you do in an already setup repo.

- change `TODO_RENAME` in `./Makefile` to name your project (lowercase) (will tag all docker resources with this name so you can easily manage them)
- `make init` (it will creat envs, and setup interractive bash to you can run you npm init commands)
- (in container bash)
  - `pnpm init` etc...(you can create a monorepo/template project, whatever from here)

Once everything is first setup (as soon as you have your project initialized)
You can trash:

- the file `./docker/dev/Dockerfile.devInit`
- in file `./Makefile` the lines:
  - `init:` (the whole block)
  - `COMPOSE_INIT: ...`
- `LICENSE.md` unless you're me lol
- this `README.md` (the doc for contributors explaining how to use this setuped environment is located in `./docs/docker-dev-env.md`)

## Issues / Contrib

Feel free to open an issue or contribute to the project on GitHub.
