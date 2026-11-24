# syntax=docker/dockerfile:1

# Build stage: download and verify PowerShell and the .NET SDK. Nothing from this stage
# reaches the sandbox except the files copied into /out.
FROM ubuntu:26.04 AS build

ARG TARGETARCH
ARG PWSH_VERSION=7.6.5
# Release channel, e.g. "10.0": resolves to the latest SDK in that channel at build time.
ARG DOTNET_CHANNEL=10.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl jq libc-bin && \
    rm -rf /var/lib/apt/lists/*

# Microsoft's naming for the CPU architectures that Docker calls amd64 and arm64.
RUN case "${TARGETARCH}" in \
      amd64) echo x64 > /arch ;; \
      arm64) echo arm64 > /arch ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac

# PowerShell. The release publishes its checksums as a UTF-16 file, hence iconv.
RUN set -eu; \
    arch="$(cat /arch)"; \
    base="https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}"; \
    file="powershell-${PWSH_VERSION}-linux-${arch}.tar.gz"; \
    curl -fsSL -o "/tmp/${file}" "${base}/${file}"; \
    curl -fsSL "${base}/hashes.sha256" | iconv -f UTF-16 -t UTF-8 | tr -d '\r' | \
      grep -F "${file}" | sed 's/ \*/  /' > /tmp/pwsh.sha256; \
    test -s /tmp/pwsh.sha256; \
    (cd /tmp && sha256sum -c pwsh.sha256); \
    mkdir -p /out/opt/pwsh /out/usr/local/bin; \
    tar -xzf "/tmp/${file}" -C /out/opt/pwsh; \
    chmod 755 /out/opt/pwsh/pwsh; \
    ln -s /opt/pwsh/pwsh /out/usr/local/bin/pwsh

# .NET SDK. URL and SHA-512 come from Microsoft's release metadata for the channel.
RUN set -eu; \
    arch="$(cat /arch)"; \
    curl -fsSL -o /tmp/releases.json \
      "https://builds.dotnet.microsoft.com/dotnet/release-metadata/${DOTNET_CHANNEL}/releases.json"; \
    jq -r --arg rid "linux-${arch}" \
      '.releases[0].sdk.files[] | select(.rid == $rid and (.name | endswith(".tar.gz"))) | "\(.hash) \(.url)"' \
      /tmp/releases.json > /tmp/sdk.txt; \
    test "$(wc -l < /tmp/sdk.txt)" -eq 1; \
    read -r hash url < /tmp/sdk.txt; \
    curl -fsSL -o /tmp/dotnet-sdk.tar.gz "${url}"; \
    echo "${hash}  /tmp/dotnet-sdk.tar.gz" | sha512sum -c -; \
    mkdir -p /out/opt/dotnet; \
    tar -xzf /tmp/dotnet-sdk.tar.gz -C /out/opt/dotnet; \
    ln -s /opt/dotnet/dotnet /out/usr/local/bin/dotnet

# Final stage: files only. The workload must supply the native libraries
# (ICU, OpenSSL, libstdc++, zlib, Kerberos), which the sandbox templates do.
FROM scratch
COPY --from=build /out/ /
