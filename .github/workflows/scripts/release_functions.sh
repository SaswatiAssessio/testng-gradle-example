#!/bin/bash
set -e

# Text colours
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

###############################
# Release Candidate Functions #
###############################
function check_dependent_workflows() {
  printf "${YELLOW}Checking for dependent workflows...${RESET}\n"
  echo "WORKFLOW_DEPS=false" >> $GITHUB_ENV
  local WORKFLOW_JOBS_URL
  local WORKFLOW_STEP_STATUS
  while read r; do
    # Skip passed in workflow
    if [[ $r == *"$1"* ]]; then
      continue
    fi
    # Query Github API for conclusion of last workflow in master branch
    WORKFLOW_JOBS_URL=$(curl -s \
        -H 'Accept: application/vnd.github.v3+json' \
        -H "Authorization: Bearer ${GH_TOKEN}" \
        "https://api.github.com/repos/SaswatiAssessio/$r?branch=master&per_page=1" | jq -r '.workflow_runs[0].jobs_url' )
    # Query Github API for status of the 'Check Workflow Dependencies' step from the 'build' job
    WORKFLOW_STEP_STATUS=$(curl -s \
        -H 'Accept: application/vnd.github.v3+json' \
        -H "Authorization: Bearer ${GH_TOKEN}" \
        "$WORKFLOW_JOBS_URL" | jq -r '.jobs[] | select(.name == "build") | .steps[] | select(.name == "Check Workflow Dependencies") | .status' )

    # If workflow job step status is not "completed" then flag to Github env and stop
    printf "${r}: ${WORKFLOW_STEP_STATUS}\n"
    if [ ! "$WORKFLOW_STEP_STATUS" = "completed" ]; then
      echo "WORKFLOW_DEPS=true" >> $GITHUB_ENV
      break
    fi
  done <.github/workflows/scripts/dependent-workflows.txt
}
