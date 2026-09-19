# Security Policy

## Reporting a Vulnerability

If you believe you have found a security vulnerability in roscord, or one of its dependencies, please report it privately through GitHub's [private vulnerability reporting](https://github.com/PondLabs/roscord/security/advisories/new) rather than opening a public issue.

Please include enough detail to reproduce: the version you are running (shown on the About page), your platform, and the steps you took.

## Scope

roscord is a hard fork of [Commet](https://github.com/commetchat/commet). Vulnerabilities in Matrix protocol handling, the vendored LiveKit and WebRTC packages under `third_party/`, or the Rust audio crates may also affect upstream Commet, and vice versa. If a report concerns upstream code rather than this fork's changes, please also notify the Commet project through its own security policy.
