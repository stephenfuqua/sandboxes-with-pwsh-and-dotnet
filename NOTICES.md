# Notices for this repository

Copyright (c) 2026, Stephen A. Fuqua.

Licensed under the [Apache License, Version 2.0](LICENSE) (the "License").

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

- PowerShell and the .NET SDK are MIT-licensed Microsoft software, downloaded
  from Microsoft's official release tarballs. Their license and third-party
  notices ship in the image under `/opt/pwsh` and `/opt/dotnet` (`LICENSE.txt`,
  `ThirdPartyNotices.txt`).
- ICU comes from Debian's `libicu76` package, whose copyright file lists ICU
  under an MIT-style license. The mixin copies only the three shared libraries,
  not that copyright file.
- The sandbox workloads are governed by the terms of `docker/sandbox-templates`,
  which are not explicitly stated anywhere.
