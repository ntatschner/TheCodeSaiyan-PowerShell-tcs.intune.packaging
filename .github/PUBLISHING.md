# Publishing tcs.intune.packaging to the PowerShell Gallery

This repository publishes the `tcs.intune.packaging` module (`modules/tcs.intune.packaging`) to the
PowerShell Gallery with GitHub Actions. The jobs themselves live in the shared workflows repository
`ntatschner/tcs-shared-workflows`; the files in `.github/workflows` here only call them with this
module's name and path.

## Workflows

| File | Name in the Actions tab | What it does |
| --- | --- | --- |
| `ci-validate.yml` | CI Validate | Runs on pull requests and pushes to `main`: shared module validation (manifest, PSScriptAnalyzer, import, `.github/scripts/module-smoke-tests.ps1`), a PSScriptAnalyzer lint job and the Pester tests on Windows PowerShell 5.1 and PowerShell 7 on Windows. |
| `create-version-tag.yml` | Create Version Tag | Runs after a successful CI Validate run on `main` (and on pushes to `main` that change the manifest, or manually). If `ModuleVersion` in `tcs.intune.packaging.psd1` is greater than the latest `v*` tag, it creates and pushes the tag `v<ModuleVersion>`. |
| `publish-to-psgallery.yml` | Publish to PSGallery | Validates the module (manifest, PSScriptAnalyzer, import, gallery version check), publishes it to the PowerShell Gallery and, when run on a `v*` tag, creates a GitHub release for that version. |
| `generate-docs.yml` | Generate PowerShell Documentation | Regenerates the PlatyPS markdown help in `docs/` and commits it to `main`. On pull requests it only checks that the help generates. |

The tag and docs workflows chain off the workflow name `CI Validate`; do not rename `ci-validate.yml`'s `name:`.

## Prerequisites

### PowerShell Gallery API key

1. Sign in to the [PowerShell Gallery](https://www.powershellgallery.com/) and open **API Keys**.
2. Create a key with the **Push new packages and package versions** scope.
3. Set its glob pattern so it covers the module name, for example `tcs.intune.packaging` or `tcs.*`.
   A key whose glob does not match the module name cannot publish it.

### Repository secret

Add the key as a repository secret named exactly `PSGALLERY_API_KEY`
(**Settings** > **Secrets and variables** > **Actions** > **New repository secret**).
No other secret is needed: the tag and release steps use the workflow's own `GITHUB_TOKEN`.

## Releasing a new version

1. On a branch, bump `ModuleVersion` in `modules/tcs.intune.packaging/tcs.intune.packaging.psd1`
   (semantic versioning) and add a matching section to `CHANGELOG.md`.
2. Open a pull request and merge it to `main` once CI Validate passes.
3. After CI Validate succeeds on `main`, **Create Version Tag** creates and pushes the tag `v<version>`
   (for example `v0.4.0`). Nothing is tagged when the version is not greater than the latest tag.
4. **Start the publish manually.** A tag pushed by a workflow with the default `GITHUB_TOKEN` does not
   trigger other workflows, so the tag push above does **not** start Publish to PSGallery. Go to
   **Actions** > **Publish to PSGallery** > **Run workflow**, choose the tag `v<version>` (not `main`)
   in the "Use workflow from" list, and run it. Running it on the tag publishes the tagged commit and
   creates the GitHub release `v<version>`.
5. Check the run summary, then confirm the new version on the PowerShell Gallery.

To have tags start the publish automatically instead, change the `repo-token` secret passed in
`create-version-tag.yml` from `secrets.GITHUB_TOKEN` to a personal access token (or GitHub App token)
with `contents: write` on this repository, stored as a repository secret. Tags pushed with such a token
do trigger the `push: tags: v*` trigger of `publish-to-psgallery.yml`.

Pushing a `v*` tag yourself (`git tag v0.4.0` then `git push origin v0.4.0`) also starts the publish,
because the push comes from your account rather than from a workflow.

### Force publish

The manual run has a **Force publish** option. Without it the workflow skips publishing when the
version already exists on the gallery. The PowerShell Gallery never accepts the same version twice,
so bump `ModuleVersion` rather than relying on this option.

## Troubleshooting

- **Publish fails with an authorisation error**: check the secret is named `PSGALLERY_API_KEY`, the key
  has not expired, it has push rights, and its glob pattern covers `tcs.intune.packaging`.
- **Publish skipped: version already exists**: bump `ModuleVersion` and release again.
- **No tag was created**: the manifest version is not greater than the latest `v*` tag, or CI Validate
  failed on `main`.
- **Import fails during validation**: the module requires `tcs.core` 0.3.0 or later
  (`RequiredModules`); make sure that version is on the PowerShell Gallery.
- **Logs**: open the run in the **Actions** tab and expand the failing step.

## Resources

- [Publishing packages to the PowerShell Gallery](https://learn.microsoft.com/powershell/gallery/how-to/publishing-packages/publishing-a-package)
- [Triggering a workflow from a workflow (GITHUB_TOKEN limitation)](https://docs.github.com/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow)
