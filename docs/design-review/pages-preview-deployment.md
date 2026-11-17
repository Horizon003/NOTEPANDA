# Interactive preview deployment status

The latest native Flutter source is packaged as a sample-data browser preview, with screen navigation, 320/360/390/430/tablet width controls and 100/130/200% text scaling. It does not use production accounts or publish backend changes. The wrapper no longer links an old APK as if it contained the latest UI.

`tools/live_preview/build.sh` now builds with the GitHub project Pages base `/pharm-d-with-hyzen/app/`. The previous `/app/` base would fail to load under this repository's Pages URL. Override HYZEN_PREVIEW_BASE_HREF for another hosting path.

The existing, registered `account-ui-review.yml` workflow builds the fixture entrypoint, runs analysis/tests, uploads a review artifact and deploys through the existing github-pages environment. It avoids requiring production backend secrets to review sample UI. The existing protected environment remains intact; no branch protection/deployment gate was changed. The separate production web-preview workflow is untouched.

After GitHub authentication is restored, push `work/monochrome-motion-1.5.5`, then dispatch:

```
gh workflow run account-ui-review.yml --ref work/monochrome-motion-1.5.5
```

Check that both build and deploy jobs succeed before sharing the expected Pages address. Any existing github-pages environment approval or branch policy must still be satisfied. The current task could not inspect those settings because all authenticated API access returned HTTP 401.

Local verification: release Flutter web build succeeded; YAML and shell checks passed. Playwright loaded the packaged build at the real project prefix and opened Home, Study, Office, Settings, Notifications and Goals. The wrapper's width and text controls were exercised at 320dp and 200%. No uncaught runtime/overflow errors were recorded; this is not an Android performance measurement or live Drive/camera verification. Evidence and actual browser screenshots: `hyzen_flutter/qa/pages-preview/`.

Publication remains blocked: the workspace GH_TOKEN is invalid, no stored fallback login is available, and the inspected public Pages URLs return 404. No live deployment link is claimed. The source commits, workflow and local static preview package remain available pending reauthentication.
