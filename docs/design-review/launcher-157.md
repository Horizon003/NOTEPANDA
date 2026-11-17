# Larger launcher and 1.5.7+16 Android preparation

The owner asked for a newly generated APK and a larger logo inside the app icon. Both adaptive icon definitions now point to a shared drawable with -12dp layer insets. The existing approved panda pixels remain unchanged; its original 64dp artwork on the 108dp layer now occupies approximately 78.2dp (22.2% larger) before the launcher applies its mask. Legacy icon artwork already fills its asset and is retained.

`hyzen_flutter/qa/launcher/larger-icon-masks.png` compares circle and rounded-square masks by rendering the old and new layer geometry in Chromium. It is a layout simulation, not a capture from an Android launcher. The native launcher still needs checking for OEM masks, animations and clipping.

The next build uses 1.5.7+16 so it can update the published 1.5.6+15. The registered signed-release workflow has matching filenames, checksums, metadata assertions, artifact names and a new release tag. Its update test now installs 1.5.6 as the baseline. The production package ID, certificate verification and backend settings remain unchanged. No replacement signing key or debug signing fallback is introduced.

The production keystore is stored in GitHub Secrets and is absent locally. Local Android SDK tools are also absent. The workspace's inherited GitHub token is invalid; a GitHub device authorization flow was opened to restore access for the signed CI build. No APK or release is claimed before that build and validation succeed.

Validation for this source: analyzer clean, all 178 Flutter tests pass, launcher XML parses, and workflow/package version checks agree on 1.5.7+16. A local universal-release build was attempted and stopped with “No Android SDK found”; it did not produce an APK.
