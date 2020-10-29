# kube-lint GitHub action

This is a GitHub action for scanning Kubernetes deployment files with [kube-linter](https://github.com/stackrox/kube-linter).  This includes both the action itself (.github/actions/kubelint) and sample GitHub workflow (.github/workflows) and a test YAML.

Quick deployment:

1.  Create a new GitHub repo.
2.  Push all files from this sample into the repo.
3.  The `kube-linter.yml` workflow will run as an action every time there's a new push to this repo.

More info on creating a repo with a GitHub action like this and using it broadly can be [found here](https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/creating-a-composite-run-steps-action)

The action takes two parameters.

```
      - name: Scan repo
        id: kube-lint-repo
        uses: ./.github/actions/kube-lint
        with:
          directory: yamls
          config: .kube-linter/config.yaml
```

* `directory` is mandatory -- this is the directory of deployment files to scan.  
* `config` is optional -- this is the path to a [configuration file](https://github.com/stackrox/kube-linter/blob/main/config.yaml.example) if you wish to use a non-default configuration.

LATEST TESTED VERSION: 0.1.1
