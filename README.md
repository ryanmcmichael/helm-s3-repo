# Helm S3 Publisher

A GitHub Action for publishing Helm charts to AWS S3.

## Usage

Inputs:
* `token` The GitHub token with write access to the target repository
* `AWS_ACCESS_KEY_ID` AWS access key ID
* `AWS_SECRET_ACCESS_KEY` AWS Secret access key
* `charts_bucket` The s3 bucket containing helm charts
* `charts_dir` The charts directory, defaults to `charts`
* `charts_url` The GitHub Pages URL, defaults to `https://<OWNER>.github.io/<REPOSITORY>`
* `owner` The GitHub user or org that owns this repository, defaults to the owner in `GITHUB_REPOSITORY` env var
* `repository` The GitHub repository, defaults to the `GITHUB_REPOSITORY` env var
* `target_dir` The target directory to store the charts, defaults to `.`
* `linting` Toggle Helm linting, can be disabled by setting it to `off`
* `commit_username` Explicitly specify username for commit back, default to `GITHUB_ACTOR`
* `commit_email` Explicitly specify email for commit back, default to `GITHUB_ACTOR@users.noreply.github.com`
* `app_version` Explicitly specify app version in package. If not defined then used chart values.
* `chart_version` Explicitly specify chart version in package. If not defined then used chart values.
* `index_dir` The location of `index.yaml` file in the repo, defaults to the same value as `target_dir`

## Examples

Package and push all charts in `./charts` dir to `charts-bucket` s3 bucket:

```yaml
name: release
on:
  push:
    paths:
      - '**'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Publish Helm charts to S3
        uses: ryanmcmichael/helm-s3-repo@master
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          charts_bucket: charts-bucket
```
