# Security Policy

## Supported Versions

LunaOs is currently under active development. Security fixes are prioritized for the latest version available on the default branch.

| Version | Supported |
|---|---|
| Latest default branch | :white_check_mark: |
| Older commits | :x: |
| Unreleased development builds | Best effort |

Since LunaOs is an experimental operating system, there are currently no guarantees of long-term security support for older versions.

## Reporting a Vulnerability

If you discover a security vulnerability in LunaOs, please report it responsibly.

**Please do not disclose security vulnerabilities through public GitHub Issues, Discussions, or Pull Requests.**

### Preferred Reporting Method

Use GitHub's Private Vulnerability Reporting feature:

1. Navigate to the [LunaOs repository](https://github.com/slowy07/LunaOs).
2. Open the **Security** tab.
3. Navigate to **Advisories**.
4. Select **Report a vulnerability**.
5. Submit your vulnerability report with as much technical detail as possible.

Reports submitted through this feature are private and will only be visible to authorized repository maintainers.

If private vulnerability reporting is unavailable, please contact the maintainer through GitHub to request a private communication channel. Do not disclose vulnerability details publicly.

### What to Include in Your Report

To help us understand and reproduce the vulnerability, please include:

- **Vulnerability Type:** The category of the vulnerability (e.g., memory corruption, privilege escalation, buffer overflow, race condition).
- **Affected Component:** The specific subsystem, module, or source file.
- **Affected Version:** The commit hash or version where the vulnerability was discovered.
- **Description:** A clear explanation of the vulnerability and its potential impact.
- **Steps to Reproduce:** Detailed instructions to reproduce the issue.
- **Proof of Concept (PoC):** A minimal demonstration, test case, or relevant code when possible.
- **Impact Assessment:** Explain what an attacker could potentially achieve by exploiting the vulnerability.
- **Suggested Fix:** If available, provide recommendations for mitigating or fixing the issue.

Please remove passwords, private keys, personal information, and other sensitive data from any logs or attachments.

## Security Scope

The following components are considered within the scope of this security policy.

### Kernel and Memory Management

- Kernel memory corruption.
- Physical and virtual memory management vulnerabilities.
- Page table manipulation and paging vulnerabilities.
- Heap and memory allocator corruption.
- Out-of-bounds memory access.
- Use-after-free and double-free vulnerabilities.
- Stack corruption and stack overflow.

### Process Management and Scheduling

- Process isolation vulnerabilities.
- Unauthorized access between processes.
- Race conditions in process scheduling.
- SMP synchronization vulnerabilities.
- Privilege escalation between execution contexts.

### Interrupts and Hardware Management

- Interrupt Descriptor Table (IDT) vulnerabilities.
- Interrupt handling and exception handling flaws.
- Local APIC and IO-APIC vulnerabilities.
- ACPI parsing vulnerabilities.
- Hardware driver vulnerabilities.

### Filesystem and Storage

- Virtual filesystem vulnerabilities.
- Disk access and storage corruption.
- ATA/IDE driver vulnerabilities.
- Unauthorized access to filesystem resources.
- Improper validation of filesystem metadata.

### Network Stack and Services

- Ethernet driver vulnerabilities.
- IPv4, ARP, ICMP, and TCP implementation flaws.
- Packet parsing vulnerabilities.
- Buffer overflow in network operations.
- Unauthorized access through the built-in HTTP service.
- Remote code execution through network-facing components.

### Bootloader and Initialization

- Bootloader security vulnerabilities.
- Kernel loading and initialization flaws.
- Improper validation of boot information.
- Vulnerabilities in memory layout and initialization.

### Build System and Repository Infrastructure

- Security vulnerabilities in official build scripts.
- Unsafe handling of build artifacts.
- Vulnerabilities in official release artifacts and distribution mechanisms.

## Out of Scope

The following issues are generally not considered security vulnerabilities unless they demonstrate a direct security impact on LunaOs:

- Bugs that only cause crashes without a security implication.
- Performance issues and general stability problems.
- Issues in unsupported third-party software or external emulators.
- Vulnerabilities requiring physical access to hardware, unless they demonstrate a security flaw in LunaOs itself.
- Social engineering attacks against contributors or maintainers.
- Issues in unrelated third-party applications.

## Responsible Disclosure

We ask security researchers to:

1. Give maintainers reasonable time to investigate and address reported vulnerabilities.
2. Avoid publicly disclosing vulnerability details before a coordinated disclosure agreement.
3. Avoid exploiting vulnerabilities against systems or users without authorization.
4. Avoid accessing, modifying, or destroying data that does not belong to them.
5. Avoid disrupting services or performing unnecessary destructive testing.

We appreciate responsible security research and contributions that help improve LunaOs.

## Response and Disclosure Process

After receiving a vulnerability report, the maintainer will make reasonable efforts to:

1. Acknowledge receipt of the report.
2. Review and validate the reported vulnerability.
3. Determine its severity and potential impact.
4. Develop and test an appropriate fix.
5. Coordinate disclosure with the reporter when appropriate.
6. Publish relevant security fixes and advisories when ready.

Response and remediation timelines depend on the severity, complexity, and available maintainer resources. No fixed response-time or resolution-time guarantee is provided.

## Security Updates

Security-related fixes and updates will be published through the official repository:

https://github.com/slowy07/LunaOs

Security advisories, when appropriate, will be published through GitHub Security Advisories.

---

Thank you for helping make LunaOs more secure!
