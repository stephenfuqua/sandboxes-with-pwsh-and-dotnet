# sandboxes-with-pwsh-and-dotnet

Docker images for use with [Docker Sandbox](https://docs.docker.com/ai/sandboxes), extending official `docker/sandbox-templates` base images with PowerShell and the .NET SDK.

Note: for any non-trivial Dotnet application, the local sandbox startup will need to allow some network access so that NuGet packages can be installed / restored.

> [!WARNING]
> While this gives the agent access to build tools, is it a step too far, partially undoing the advantages of having a sandbox?

## What's included

| Dockerfile | Base image |
| --- | --- |
| `claude-with-pwsh-and-dotnet.dockerfile` | [`docker/sandbox-templates:claude-code`](https://hub.docker.com/r/docker/sandbox-templates) |
| `copilot-with-pwsh-and-dotnet.dockerfile` | [`docker/sandbox-templates:copilot`](https://hub.docker.com/r/docker/sandbox-templates) |

Both base images are pinned by digest. On top of each:

- **PowerShell** `v7.6.5`, installed from Microsoft's official apt package feed
- **.NET SDK** `10.0`, installed from Microsoft's official apt package feed

## Why

Docker Sandbox does not use the local Docker registry, so images built for it must be published to a registry (e.g. Docker Hub) before they can be selected. These images bundle PowerShell and .NET tooling on top of the Claude Code and Copilot sandbox templates for workflows that need them.

## Building

```bash
docker build -f claude-with-pwsh-and-dotnet.dockerfile -t <your-dockerhub-username>/claude-with-pwsh-and-dotnet .
docker build -f copilot-with-pwsh-and-dotnet.dockerfile -t <your-dockerhub-username>/copilot-with-pwsh-and-dotnet .
```

## Publishing

```bash
docker push <your-dockerhub-username>/claude-with-pwsh-and-dotnet
docker push <your-dockerhub-username>/copilot-with-pwsh-and-dotnet
```

By default, Docker Hub repositories are publicly accessible — anyone can pull the image once pushed. Set the repository to private on Docker Hub if that's not intended.

## Licensing notes

- The base images are governed by the terms of `docker/sandbox-templates`, which are not explicitly stated anywhere.
- PowerShell and the .NET SDK are MIT-licensed Microsoft software, installed here from Microsoft's official apt repositories (`packages.microsoft.com`). Their license/copyright notices are included automatically as part of the installed apt packages (e.g. `/usr/share/doc/powershell/copyright`, `/usr/share/doc/dotnet-sdk-*/copyright`).

## Notes

- The Ubuntu version used for the PowerShell apt feed is hard-coded to `24.04` in both dockerfiles, since Microsoft has not yet published PowerShell packages for the newer Ubuntu version (`26.04`) used by both base sandbox images as of this writing. Revisit this pin when Microsoft adds support.
