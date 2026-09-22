# ssh-key-distributor

Safely distribute an SSH public key to root accounts across hosts listed in a file.

## Overview

`ssh-key-distributor` is a small Shell utility for deploying one SSH public key to multiple hosts. It reads a list of target hosts, connects to each host over SSH, and adds the selected public key to the root account's `authorized_keys` file.

The script is intended for administrators who need to bootstrap or update root SSH access consistently across a group of machines without manually logging in to every host. It uses the local SSH client's configuration and authentication, so existing aliases, identity files, bastion settings, and host-key checking policies can be reused.

> **Use with care:** this tool changes root account access on every host it successfully reaches. Review the host list and key before running it, and test against a non-production host first.

## How it works

1. The script reads hosts from an input file, one host per line.
2. It skips blank lines, allowing host lists to remain readable.
3. For each host, it opens an SSH connection as `root`.
4. It appends the public key to root's `~/.ssh/authorized_keys` file on that host.
5. SSH reports connection or permission errors for hosts that cannot be updated, while processing can continue for the remaining hosts.

The public key is treated as data when it is sent to the remote shell. Ensure that the remote root account can be reached using your current SSH credentials or configuration before using the script across a larger fleet.

## Requirements

- A POSIX-compatible shell.
- An SSH client on the local machine.
- Network access to each target host.
- Root SSH access to each target host, either directly or through your SSH configuration.
- A public key file, such as `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`.

## Usage

First, create a host list. Put one hostname, IP address, or SSH config alias on each line:

```text
# hosts.txt
server-01.example.com
server-02.example.com
10.0.0.23
```

Then run the distributor with the script, public key, and host-list file:

```bash
./ssh-key-distributor.sh ~/.ssh/id_ed25519.pub hosts.txt
```

A typical invocation using an RSA key might look like this:

```bash
./ssh-key-distributor.sh \\
  ~/.ssh/id_rsa.pub \\
  ./production-hosts.txt
```

If the script supports standard SSH options through the local SSH configuration, define them in `~/.ssh/config` and use the configured host aliases in the host list. For example:

```sshconfig
Host web-01
    HostName web-01.example.com
    User root
    IdentityFile ~/.ssh/admin_ed25519
```

```text
# hosts.txt
web-01
```

> The exact argument order is determined by the script's command-line interface. Run `./ssh-key-distributor.sh --help` (or inspect the script's usage output) if your checkout uses a different script filename or argument order.

## Verifying access

After the command completes, verify the key on a target host:

```bash
ssh -i ~/.ssh/id_ed25519 root@server-01.example.com
```

For a dry run, review the host list and key first, then test with a single host before distributing to the full file. Do not place private keys in the repository or pass a private key to the script; only the corresponding `.pub` file is needed.

## Security notes

- Protect the public-key file and host list from unauthorized modification.
- Confirm every host in the input file before running the command.
- Keep SSH host-key verification enabled; do not bypass it with `StrictHostKeyChecking=no` unless you fully understand the risk.
- Use the least-privileged operational process available and restrict root SSH access where possible.
- Check the resulting `authorized_keys` entries and remove the key from hosts when it is no longer required.
