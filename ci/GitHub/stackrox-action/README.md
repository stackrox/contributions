# StackRox GitHub actions

This is a GitHub action for scanning Docker images and checking them against policies.  This sample includes both the actions themselves (.github/actions) and a sample workflow (.github/workflows)

Quick deployment:

1.  Create a new GitHub repo.
2.  Push all files from this sample into the repo.
3.  The `main.yml` workflow will run as an action every time there's a new push to this repo.

More info on creating a repo with a GitHub action like this and using it broadly can be [found here](https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/creating-a-composite-run-steps-action)

There are two actions in this sample -- `stackrox-scan` and `stackrox-check`.

`stackrox-scan` returns the JSON with the full analysis of the image composition including components & vulnerabilities.  This is useful for getting everything StackRox knows about the image.

`stackrox-check` tests the image against configured policies.  If any violated policies are enforced, this will pass a non-zero return code back, causing the build to fail.

Both actions take the same parameters:

```
    - id: check
      uses: ./.github/actions/stackrox-check
      with:
        image: 'vulnerables/cve-2017-7494'
        central-endpoint: ${{ secrets.ROX_CENTRAL_ENDPOINT }}
        api-token: ${{ secrets.ROX_API_TOKEN }}
```

All parameters are mandatory.  You should store the API token and the endpoint for Central (in the format `stackrox.contoso.com:443`) in [GitHub encrypted secrets](https://docs.github.com/en/free-pro-team@latest/actions/reference/encrypted-secrets).

* `image` is the image to be scanned -- `vulnerables/cve-2017-7494` for example.  
* `central-endpoint` is the location of the StackRox Central deployment.  
* `api-token` is the StackRox API token to be used.  This token must have at least CI privileges.

LATEST TESTED VERSION: 3.0.53.0
