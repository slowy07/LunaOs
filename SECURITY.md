# Security Policy

LunaOs is a hobby operating system. It is not intended for production or
untrusted environments, but security reports are still welcome.

## Supported Versions

Only the latest commit on `main` is supported.

## Reporting a Vulnerability

Do **not** open a public issue for a security problem.

Use GitHub's private reporting: go to the **Security** tab of
[slowy07/LunaOs](https://github.com/slowy07/LunaOs) and choose
**Report a vulnerability** (GitHub Security Advisories). Include:

- affected component (bootloader, kernel, VFS, network stack, a `software/` app)
- steps to reproduce, including the exact `make` target and QEMU command line
- what you expected vs. what happened

You can expect an initial reply within a couple of weeks, best effort. This is
a spare-time project, so there is no formal SLA or bug bounty.

## Scope

In scope: kernel code, boot sectors, syscall/service dispatcher, VFS, network
driver and HTTP service, and the build scripts that produce the disk image.

Out of scope: bugs that only appear when LunaOs runs under a compromised
hypervisor or with a tampered disk image; missing hardening that has no
demonstrated impact; third-party tools (nasm, QEMU).

## Known Limitations

There is no privilege separation, no ASLR, and no user/kernel memory
protection beyond paging. Anything running on the machine is effectively
trusted. Treat this as a feature of the project's stage, not a vulnerability
report, unless you have a concrete exploit.
