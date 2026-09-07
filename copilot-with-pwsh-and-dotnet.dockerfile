FROM docker/sandbox-templates:copilot@sha256:e21edce87d378167fdd3c021a21e0856eaa37b9ed9b058dbd57140f26ced1430 AS pwsh

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-transport-https software-properties-common && \
    # Ubuntu version is hard-coded to 24 because Microsoft hasn't published Powershell yet for 26,
    # which is what sandbox@e21edce uses.
    curl -fsSL -O https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends powershell && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER agent

FROM pwsh
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends dotnet-sdk-10.0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER agent
