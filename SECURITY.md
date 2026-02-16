# Security Policy

## Scope

hushbrew runs shell commands with your user privileges. It executes `brew update`, `brew upgrade`, and `brew cleanup` — the same commands you'd run manually.

## Config file

The config file at `~/.config/hushbrew/config` is **sourced** by the script (`source "$CONFIG"`). This means arbitrary bash in that file will execute with your user privileges. Only you should have write access to this file.

Verify permissions:

```bash
ls -la ~/.config/hushbrew/config
# Should be -rw------- or -rw-r--r-- owned by your user
```

## Reporting a vulnerability

If you find a security issue, please **do not** open a public issue. Instead, email the maintainer directly. You can find contact info in the git log.

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact

You will receive a response acknowledging your report. A fix will be developed privately and released as a patch version.

## Best practices

- Don't run hushbrew as root
- Keep your `~/.config/hushbrew/` directory permissions restricted to your user
- Review the script source before installing — it's a single readable bash file
