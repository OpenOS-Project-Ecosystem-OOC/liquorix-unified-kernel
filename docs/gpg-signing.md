# GPG signing

Packages are signed with a GPG key so users can verify authenticity before
installing. Signing is optional for local builds — packages are produced
unsigned if no key is available. CI builds should always sign.

## Generating a signing key

```bash
gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Liquorix Kernel
Name-Email: liquorix@example.com
Expire-Date: 2y
%no-protection
EOF
```

Export the public key for distribution:

```bash
gpg --armor --export liquorix@example.com > liquorix-signing-key.asc
```

Export the private key for CI:

```bash
gpg --armor --export-secret-keys liquorix@example.com
```

## Local builds

If `~/.gnupg` contains a default key, the build scripts will automatically
mount it into the build container and sign packages. No extra configuration
is needed.

To use a specific key:

```bash
export GNUPGHOME=/path/to/your/gnupghome
make build-debian RELEASE=trixie
```

## CI signing (GitHub Actions)

Add the following secrets to the repository
(**Settings → Secrets and variables → Actions**):

| Secret | Value |
|---|---|
| `GPG_PRIVATE_KEY` | Output of `gpg --armor --export-secret-keys <key-id>` |
| `GPG_PASSPHRASE` | Passphrase for the key (empty string if none) |

The build workflow imports the key at the start of each job using
`scripts/lib/gpg.sh:gpg_import_ci_key()` and cleans up with `gpg_cleanup()`
after the build completes.

## Verifying a signed package

**Debian/Ubuntu:**
```bash
dpkg-sig --verify linux-image-liquorix-amd64_*.deb
```

**Arch Linux:**
```bash
gpg --verify linux-lqx-*.pkg.tar.zst.sig
```

**Fedora/openSUSE:**
```bash
rpm --checksig kernel-liquorix-*.rpm
```

## Distributing the public key

Place `liquorix-signing-key.asc` in the repo root and reference it from
the install scripts so users can import it before adding the package repo.
The Debian install script already handles this via the liquorix.net keyring.
