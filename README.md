# PAM WatchID

A PAM plugin for authenticating using the new `kLAPolicyDeviceOwnerAuthenticationWithBiometricsOrWatch` API in macOS 10.15 (or `kLAPolicyDeviceOwnerAuthenticationWithBiometricsOrCompanion` in macOS 15 or later), written in Swift.

![](https://github.com/Logicer16/pam-watchid/blob/docs/demo.gif?raw=true)

## Prerequisites

* The most up to date version of either Xcode or the Xcode command line tools (CLT) for your version of macOS. This includes all of the tools needed to build the module, including `swiftc`, `make`, and `git`. If you do not yet have either installed, you should be prompted automatically to install teh CLT when you first try to follow the [install instructions](#installation). You can also install the CLT manually with the following command:

```sh
xcode-select --install
```

## Installation

### Quick Install (Recommended)

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/logicer16/pam-watchid/HEAD/install.sh)" -- enable
```

> [!NOTE]
> If you are using macOS Sonoma or later and have already modified `sudo_local`, ensure the file still contains the original `auth       sufficient     pam_tid.so` line, with or without the comment at the start. The enable script uses this to "anchor" where the `pam_watchid.so` line will be inserted. If the line isn't present, no changes will be made.

### Manual
1. Run inside a cloned copy of the repo: 
```sh
make install
```
2. Modify the sudo pam config to include the `pam_watchid.so` module. Using the following line, follow the steps according to your version of macOS. 
  ```
  auth sufficient pam_watchid.so
  ```
   * *On macOS 14 and later:* Create/edit `/etc/pam.d/sudo_local` to include it in the list of modules, in order of execution.
   **If you are unsure of the order, place it on the first line.**
   * *On macOS 13 and earlier:* Edit `/etc/pam.d/sudo` to **include it as the first line**.

> [!IMPORTANT]
> Note that you might have other `auth` statements, **don't remove them**.
