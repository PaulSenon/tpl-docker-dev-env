# How to use docker dev env ?

This project is meant to be fully run in a containerized environment using Docker.
This is for multiple benefits:

- one command from repo cloned to contrib possible
- no host dependencies (beside Docker, Make, and Docker Compose) (it means you can dev even wiwhtout node installed)
- cross platform support (meant to be used on Windows wsl2, macOS, Linux, and work both with ARM/x86)
- environment reproducibility (every developer has the same environment, so no "it works on my machine" issues)
- one command cleanup, if you need to archive a project and freeup space you can `make clean` that will remove all containers, images, and volumes created by the project. You will lose all cache, history, etc, but nothing else. (restore like you just cloned the project)
- llms agent isolation, because you dev inside container, your agents are running isolated from host and can only acces this project folders.
- you can run as many bash instances in the same container (nb, if you kill the first one, they all die)
- when you exit container or kill `make dev` or anything, it auto soft-cleanup/stop the container (never running compose up/down)

## How to use

### First time

- `make install` => done.

### Subsequent times

you chose:

- `make dev` (to run project in dev mode)
- `make bash`(to enter dev env bash) then `pnpm run dev`

### Restore because something is broken (will restore like freshly cloned)

- `make clean-install` (will cleat all docker resources linked to project (volumes, networks, containers, images), and force rebuild base image, then install everything)

### Quickly run adhoc commands

- `make run --cmd="echo hello world"`
