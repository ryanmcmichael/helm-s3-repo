#!/bin/bash

set -o errexit
set -o pipefail

GITHUB_TOKEN=$1
AWS_ACCESS_KEY_ID=$2
AWS_SECRET_ACCESS_KEY=$3
CHARTS_BUCKET=$4
CHARTS_DIR=$5
CHARTS_URL=$6
OWNER=$7
REPOSITORY=$8
TARGET_DIR=$9
HELM_VERSION=$10
LINTING=$11
COMMIT_USERNAME=${12}
COMMIT_EMAIL=${13}
APP_VERSION=${14}
CHART_VERSION=${15}
INDEX_DIR=${16}

CHARTS=()
CHARTS_TMP_DIR=$(mktemp -d)
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_URL=""

main() {
  if [[ -z "$HELM_VERSION" ]]; then
      HELM_VERSION="3.4.2"
  fi

  if [[ -z "$CHARTS_DIR" ]]; then
      CHARTS_DIR="charts"
  fi

  if [[ -z "$OWNER" ]]; then
      OWNER=$(cut -d '/' -f 1 <<< "$GITHUB_REPOSITORY")
  fi

  if [[ -z "$REPOSITORY" ]]; then
      REPOSITORY=$(cut -d '/' -f 2 <<< "$GITHUB_REPOSITORY")
  fi

  if [[ -z "$TARGET_DIR" ]]; then
      TARGET_DIR="."
  fi

  if [[ -z "$CHARTS_URL" ]]; then
      CHARTS_URL="s3://${CHARTS_BUCKET}"
  fi

  if [[ "$TARGET_DIR" != "." && "$TARGET_DIR" != "docs" ]]; then
      CHARTS_URL="${CHARTS_URL}/${TARGET_DIR}"
  fi

  if [[ -z "$REPO_URL" ]]; then
      REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/${REPOSITORY}"
  fi

  if [[ -z "$COMMIT_USERNAME" ]]; then
      COMMIT_USERNAME="${GITHUB_ACTOR}"
  fi

  if [[ -z "$COMMIT_EMAIL" ]]; then
      COMMIT_EMAIL="${GITHUB_ACTOR}@users.noreply.github.com"
  fi

  if [[ -z "$INDEX_DIR" ]]; then
      INDEX_DIR=${TARGET_DIR}
  fi

  locate
  download
  dependencies
  if [[ "$LINTING" != "off" ]]; then
    lint
  fi
  package
  versions
  upload
}

locate() {
  for dir in $(find "${CHARTS_DIR}" -type d -mindepth 1 -maxdepth 1); do
    if [[ -f "${dir}/Chart.yaml" ]]; then
      CHARTS+=("${dir}")
      echo "Found chart directory ${dir}"
    else
      echo "Ignoring non-chart directory ${dir}"
    fi
  done
}

download() {
  tmpDir=$(mktemp -d)

  pushd $tmpDir >& /dev/null

  wget https://get.helm.sh/helm-v3.5.1-linux-amd64.tar.gz
  tar -zxvf helm-v3.5.1-linux-amd64.tar.gz
  cp linux-amd64/helm /usr/local/bin/helm

  popd >& /dev/null
  rm -rf $tmpDir
}

dependencies() {
  for chart in ${CHARTS[@]}; do
    helm dependency update "${chart}"
  done
}

lint() {
  helm lint ${CHARTS[*]}
}

package() {
  if [[ ! -z "$APP_VERSION" ]]; then
      APP_VERSION_CMD=" --app-version $APP_VERSION"
  fi

  if [[ ! -z "$CHART_VERSION" ]]; then
      CHART_VERSION_CMD=" --version $CHART_VERSION"
  fi

  helm package ${CHARTS[*]} --destination ${CHARTS_TMP_DIR} $APP_VERSION_CMD$CHART_VERSION_CMD
}

versions() {
  for chart in ${CHARTS[@]}; do
    echo "Versioning $chart"
  done
}

upload() {
  tmpDir=$(mktemp -d)
  pushd $tmpDir >& /dev/null

  git clone ${REPO_URL}
  cd ${REPOSITORY}
  git config user.name "${COMMIT_USERNAME}"
  git config user.email "${COMMIT_EMAIL}"
  git remote set-url origin ${REPO_URL}
  git checkout ${BRANCH}

  charts=$(cd ${CHARTS_TMP_DIR} && ls *.tgz | xargs)

  mkdir -p ${TARGET_DIR}

  if [[ -f "${INDEX_DIR}/index.yaml" ]]; then
    echo "Found index, merging changes"
    helm repo index ${CHARTS_TMP_DIR} --url ${CHARTS_URL} --merge "${INDEX_DIR}/index.yaml"
    mv -f ${CHARTS_TMP_DIR}/*.tgz ${TARGET_DIR}
    mv -f ${CHARTS_TMP_DIR}/index.yaml ${INDEX_DIR}/index.yaml
  else
    echo "No index found, generating a new one"
    mv -f ${CHARTS_TMP_DIR}/*.tgz ${TARGET_DIR}
    helm repo index ${INDEX_DIR} --url ${CHARTS_URL}
  fi


  AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} aws s3 sync ${TARGET_DIR} ${CHARTS_URL} --content-type "application/x-gzip"


  popd >& /dev/null
  rm -rf $tmpDir
}

main
