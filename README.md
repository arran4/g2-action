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

      # Normal use: install the latest published binary (no Go build).
      - name: Install g2
        uses: arran4/g2-action@v1
        with:
          version: 'latest'

      - name: Use g2
        run: g2 lint .

      # In a separate test job, exercise unreleased g2 changes.
      # Replace main with a branch name or full commit SHA.
      - name: Install an unreleased g2 ref
        uses: arran4/g2-action@v1
        with:
          version: 'main'
```

The action also supports installing and executing g2 in one step:

```yaml
- name: Use g2 Action
  uses: arran4/g2-action@v1
  with:
    action: 'lint .'
    mode: 'install and run'
    git-clone-timeout: '10m'
    format: 'github-actions'
```

## Release versions and source refs

- `version: latest` (the default) downloads the latest **published** GitHub release.
- `version: v0.0.104` (or another `v*` version tag) downloads that release's binary.
- `version: main`, `version: feature/my-fix`, `version: refs/pull/583/head`, or `version: <commit-sha>` fetches and compiles that g2 source ref.
- `source-ref` explicitly selects a source ref and takes precedence over `version`. Use it for a branch that resembles a release tag, or to make source builds explicit.

Source builds install the Go version required by **the selected g2 ref's `go.mod`** with `actions/setup-go@v6` (`cache: false`). They compile `./cmd/g2`, embed `ref-<short-sha>` in the version, and add the binary's installation directory to `GITHUB_PATH`. Source builds require access to `github.com/arran4/g2` and a compatible runner with Git and Go support.

To test a source ref against gentoo-packages without maintaining a separate clone/build sequence:

```yaml
- name: Install g2
  uses: arran4/g2-action@v1
  with:
    version: ${{ inputs.g2_version || 'latest' }}
```

Until a g2-action release containing this feature updates the `v1` major tag, use the feature branch explicitly for testing. Building arbitrary refs executes code from that ref; use only trusted refs and avoid sourcing untrusted PR code with privileged workflow permissions.

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| `version` | g2 release (`latest`, `v0.0.104`) or source branch/commit/ref. | `latest` | No |
| `source-ref` | Explicit g2 git ref/commit to compile, overriding `version`. | `''` | No |
| `github-token` | GitHub token to authenticate release API requests. | `${{ github.token }}` | No |
| `action` | The action to run with g2. | `''` | No |
| `mode` | The execution mode: `install`, `install and run`, or `run`. | `install` | No |
| `git-clone-timeout` | The timeout for git clone operations in g2 commands. | `''` | No |
| `format` | The output format (e.g. `github-actions`). | `''` | No |

## License

This action is distributed under the same terms as the `g2` tool itself. See the `LICENSE` file for details.
