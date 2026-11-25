# sandboxes-with-pwsh-and-dotnet

A [Docker Sandbox](https://docs.docker.com/ai/sandboxes) mixin (a "kit") that adds PowerShell and the
.NET SDK to any v3 sandbox workload: `shell`, `claude`, `copilot`, and so on. The mixin lives in
[`pwsh-dotnet-mixin/`](pwsh-dotnet-mixin/).

## What's included

| Tool | Default version | Source |
| --- | --- | --- |
| PowerShell | `7.6.5` | Official release tarball from GitHub, SHA-256 verified |
| .NET SDK | latest in channel `10.0` | Official tarball from Microsoft's release metadata, SHA-512 verified |
| ICU (`libicuuc`, `libicui18n`, `libicudata`) | Debian 13 `libicu76` | Debian package, signature verified by apt |

PowerShell installs to `/opt/pwsh` and the SDK to `/opt/dotnet`. Both are symlinked into
`/usr/local/bin`. The final image stage is `FROM scratch`, so the mixin adds only these files to the
workload.

The mixin also:

- Allows outbound HTTPS to `api.nuget.org` so `dotnet restore` works without extra policy.
- Sets `DOTNET_CLI_TELEMETRY_OPTOUT=1`, `DOTNET_NOLOGO=1` and `POWERSHELL_TELEMETRY_OPTOUT=1`.

## Requirements

- `sbx` v0.45 or later (the first release with v3 kits).
- A v3 workload. The built-in names (`shell`, `claude`, `copilot`, ...) select v3 kits. Every kit in a
  sandbox must be v3.
- Docker with Buildx, or another OCI-compatible builder, to build the mixin from source.
- amd64 or arm64.

The workload must supply OpenSSL, libstdc++, zlib and Kerberos. The Docker sandbox templates (Debian 13,
Docker Hardened Images) do. They lack ICU, which is why the mixin bundles it.

## Usage

### From source

From the repository root:

```bash
sbx run claude --name pwsh-dotnet --kit ./pwsh-dotnet-mixin
```

`sbx` builds the mixin and layers it onto the workload.

A sandbox keeps the kits it was created with. After editing the mixin, or to try different arguments,
create a sandbox with a new name.

> [!TIP]
> Optional: verify that PowerShell and Dotnet are installed correctly by
> running these commands inside the sandbox:
>
> ```bash
> pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
> dotnet --version
> cd /tmp && dotnet new console -o hello && dotnet package add Serilog && dotnet run --project hello
> ```

### Versions

| Argument | Default | Format | Build arg |
| --- | --- | --- | --- |
| `pwshVersion` | `7.6.5` | `major.minor.patch` | `PWSH_VERSION` |
| `dotnetChannel` | `10.0` | `major.minor` | `DOTNET_CHANNEL` |

Set them with `--kit-arg`:

```bash
sbx run claude --name pwsh-dotnet-9 --kit ./pwsh-dotnet-mixin --kit-arg dotnetChannel=9.0
```

`dotnetChannel` resolves to the newest SDK in that channel at build time, so builds are not
reproducible across SDK releases.

### Published image

Build the descriptor, not the Dockerfile, so the image carries the kit metadata:

```bash
docker login
docker buildx build ./pwsh-dotnet-mixin -f ./pwsh-dotnet-mixin/pwsh-dotnet-mixin.yaml \
  -t docker.io/<NAMESPACE>/pwsh-dotnet-mixin:<VERSION> --push
```

Then pass the reference to `--kit` in place of the local path:

```bash
sbx run claude --name pwsh-dotnet --kit <NAMESPACE>/pwsh-dotnet-mixin:<VERSION>
```

Docker Hub repositories are public by default. Set the repository to private if that is not what you
want; `sbx` then needs registry credentials to pull it.

## NuGet access

The mixin's network policy allows `api.nuget.org:443`, which is enough to restore packages from
nuget.org. Feeds on other hosts (a private feed, GitHub Packages, Azure Artifacts) need their own
allow rules in your sandbox policy.

## Known limitations

- **Workload warning on first use.** The first `dotnet` command in a fresh home directory prints
  `An issue was encountered verifying workloads.` `/opt/dotnet` is root-owned and read-only for the
  `agent` user, so the SDK cannot create `/opt/dotnet/metadata`. Restore, build and run are unaffected.
- **No `dotnet workload install`**, for the same reason.

## Licensing

Copyright (c) 2026, Stephen A. Fuqua.

Licensed under the [Apache License, Version 2.0](LICENSE) (the "License").

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

See [NOTICES.md](./NOTICES.md) for other license notices.
