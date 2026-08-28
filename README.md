# claude-with-pwsh-and-dotnet

A Docker image for use with [Docker Sandbox](https://docs.docker.com/ai/sandboxes), extending the official `docker/sandbox-templates:claude-code` base image with PowerShell and the .NET SDK.

## What's included

- **Base**: [`docker/sandbox-templates:claude-code`](https://hub.docker.com/r/docker/sandbox-templates) (pinned by digest)
- **PowerShell** `v7.6.5`, installed from Microsoft's official apt package feed
- **.NET SDK** `10.0`, installed from Microsoft's official apt package feed

## Why

Docker Sandbox does not use the local Docker registry, so images built for it must be published to a registry (e.g. Docker Hub) before they can be selected. This image bundles PowerShell and .NET tooling on top of the Claude Code sandbox template for workflows that need them.

## Building

```bash
docker build -f claude-with-pwsh-and-dotnet.dockerfile -t <your-dockerhub-username>/claude-with-pwsh-and-dotnet .
```

## Publishing

```bash
docker push <your-dockerhub-username>/claude-with-pwsh-and-dotnet
```

By default, Docker Hub repositories are publicly accessible — anyone can pull the image once pushed. Set the repository to private on Docker Hub if that's not intended.

## Licensing notes

- The base image is governed by the terms of `docker/sandbox-templates`, which are not explicitly stated anywhere.
- PowerShell and the .NET SDK are MIT-licensed Microsoft software, installed here from Microsoft's official apt repositories (`packages.microsoft.com`). Their license/copyright notices are included automatically as part of the installed apt packages (e.g. `/usr/share/doc/powershell/copyright`, `/usr/share/doc/dotnet-sdk-*/copyright`).

## Notes

- The Ubuntu version used for the PowerShell apt feed is hard-coded to `24.04`, since Microsoft has not yet published PowerShell packages for the newer Ubuntu version used by the base sandbox image as of this writing. Revisit this pin when Microsoft adds support.
