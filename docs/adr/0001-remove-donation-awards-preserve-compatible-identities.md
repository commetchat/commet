# Remove donation awards while preserving compatible identities

roscord removes the donation and awards-fetching affordance and its engine instead of hiding or repointing them. There is no roscord donation service for that path to feed, and merely masking the UI would have left code that reads or creates the `chat.commet.donations_client_secret` account-data secret and sends it to the live `stripe-rewards.commet.chat` host. The refresh control, confirmation flow, client, component registration, secret writer, and host therefore leave together; the retired local `running_donation_check_flow` preference is cleared during initialization.

## Compatibility identities we keep

The product name shown to users is roscord, but names that identify an installed app, persisted data, protocol, build artifact, or real upstream project remain unchanged when renaming would break compatibility:

- The `commet` executable and bundle filenames remain build and distribution identities so upgrades, launchers, and packaging continue to find the installed program.
- Application identifiers such as `chat.commet.commetapp`, the Windows AUMID, Android package names, desktop IDs, and related DBus and method-channel names remain distribution identities so an update replaces the existing app and preserves shortcuts and notifications.
- The `chat.commet` URI scheme remains registered so existing deep links continue to open.
- Matrix event types, state keys, account-data keys, and widget or LiveKit topics under `chat.commet.*` remain protocol identities because rooms, homeservers, and other clients already persist and exchange them.
- Existing on-disk directory, cache, database, and preference namespaces remain storage identities so an update can read existing user data. A removed feature may migrate its own retired key, as the donation-flow cleanup does.
- Rust crate, library, symbol, JavaScript binding, and other internal build-artifact names remain stable where generated bindings and native callers depend on them.
- Real third-party identifiers remain factual, including the `commetchat/*` dependency repositories, localized attribution to Commet's encrypted URL preview project, and the `commet-16334` Firebase project. Upstream `commet.chat` copyright attribution is also retained; PondLabs attribution is recorded alongside it in platform metadata.

These are the durable keep categories used by the repository identity guard. Display-name entries marked there as follow-up gaps are temporary exceptions, not compatibility identities.

## Badge compatibility

Profile badge display and selection are separate from awards fetching and remain supported. They read existing `chat.commet.profile_badge.*` and `chat.commet.profile_badges` account data and verify issuer signatures with known public keys. Any future issuer or key change must continue accepting badges signed by an existing trusted key, or provide an explicit migration, so already-issued badges do not disappear.

## Remaining upstream services

`push.commet.chat`, `proxy.commet.chat`, and `calendar-widget.commet.chat` remain real upstream-hosted dependencies and are tracked separately from the rebrand. They are not donation infrastructure and cannot be renamed without replacement services and, for the push gateway, migration of pushers already registered on homeservers.
