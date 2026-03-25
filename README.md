# g2 GitHub Action

This GitHub Action downloads and installs [`g2`](https://github.com/arran4/g2), a set of Gentoo CLI tools for working with Manifest files, generating static overlay sites, and more.

## Usage

```yaml
name: Example workflow
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install g2
        uses: arran4/g2-action@v1
        with:
          # Optional: specify a version. Defaults to 'latest'
          version: 'latest'

      - name: Use g2
        run: |
          g2 lint .

      - name: Use g2 Action
        uses: arran4/g2-action@v1
        with:
          # Optional: specify an action
          action: 'lint .'
          # Optional: skip installation if already installed
          install: 'false'
```

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| `version` | The version of `g2` to install (e.g. `latest`, `v0.0.18`). | `latest` | No |
| `github-token` | GitHub token to authenticate API requests to prevent rate limiting. | `${{ github.token }}` | No |
| `action` | The action to run with `g2`. | `''` | No |
| `install` | Whether to install `g2` or not. | `true` | No |

## License

This action is distributed under the same terms as the `g2` tool itself. See the `LICENSE` file for details.
