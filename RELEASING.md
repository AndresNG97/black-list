# Releasing on CurseForge

## First release (manual)

1. Sign in at https://authors.curseforge.com and click **Create Project** → World of Warcraft → Addons.
2. Fill in the form with `curseforge/project.md` and paste `curseforge/description.md` as the description.
3. Upload `PlayerBlacklist-<version>.zip`. The zip must contain one folder called `ListaNegra` with `ListaNegra.toc` inside.
   Pick the WoW: Forever game version and paste the 1.0.0 changelog.
4. Wait for CurseForge moderation to approve the project (usually a day or two).

To build the zip yourself, copy `ListaNegra.toc`, `LICENSE`, `README.md`, `CHANGELOG.md` and the folders `Core`, `Locales`, `Detection`, `UI` and `Slash.lua` into a folder called `ListaNegra`, and zip that folder.

## Later releases (automatic, optional)

The workflow in `.github/workflows/release.yml` uses the BigWigs packager to build the zip and upload it when you push a version tag.

1. Copy the **Project ID** from the project's page on CurseForge (right column, "About Project").
2. Add it to `ListaNegra.toc`, under the other `##` lines:
   ```
   ## X-Curse-Project-ID: 123456
   ```
3. Create an API token at https://authors.curseforge.com/account/api-tokens.
4. In GitHub: **Settings → Secrets and variables → Actions → New repository secret**, name `CF_API_KEY`, value the token.
5. For each release: update `## Version` in the .toc and `CHANGELOG.md`, commit, then tag and push:
   ```
   git tag v1.0.1
   git push origin v1.0.1
   ```

If the packager doesn't recognize the WoW: Forever interface version yet, the upload fails or lands on the wrong game version. In that case keep uploading by hand: the GitHub release still has the zip.
