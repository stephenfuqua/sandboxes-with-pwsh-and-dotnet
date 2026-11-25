# Host verification checklist (Task 5)

Run on a machine with `sbx` installed. Replace names as needed; use a **new sandbox name for every run**
(existing sandboxes keep the kits they were created with). Run from the repository root.
Record the `sbx --version` you used.

## 1. Smoke on each workload

```bash
sbx --version
for w in shell claude copilot; do
  sbx run $w --name pd-$w-1 --kit ./pwsh-dotnet-mixin
done
```

Inside each sandbox:

```bash
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'   # expect 7.6.5
dotnet --version                                                   # expect 10.0.x
env | grep -E 'DOTNET_|POWERSHELL_'                                # expect the 3 opt-out variables
```

Expected: a one-time "verifying workloads" message on first `dotnet` use is a known, accepted limitation.
Note anything else, especially a missing-library error (OpenSSL, libstdc++, zlib, Kerberos). ICU is bundled
in the mixin, so an ICU error means the bundled libraries were not picked up.

## 2. Functional: NuGet restore with only the kit's network rule

```bash
cd /tmp && dotnet new console -o hello && dotnet run --project hello   # expect Hello, World!
```

Then on the host: `sbx policy log` and list any hosts that were blocked or needed approval during restore.

## 3. Negative: rule is what grants access

Edit a copy of the descriptor (e.g. `./pwsh-dotnet-mixin-nonet/`) with the `network-policy` capability removed,
run on a new name, and repeat step 2. Expected: restore fails. If it succeeds, your own policy already allows
NuGet, so note that.

## 4. Report back

- `sbx --version`
- Pass/fail per workload for step 1, with any errors verbatim
- Hosts seen in `sbx policy log` during restore
- Step 3 outcome
- Anything unexpected
