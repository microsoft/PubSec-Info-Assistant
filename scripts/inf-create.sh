#!/bin/bash
set -e

printInfo() {
    printf "$YELLOW\n%s$RESET\n" "$1"
}

figlet Infrastructure

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/load-env.sh"
pushd "$DIR/../infra" > /dev/null

# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

#set up variable for the bicep deployment
if [ -f "random.txt" ]; then
  randomString=$(cat random.txt)
else  
  randomString=$(mktemp --dry-run XXXXX)
  echo $randomString >> random.txt
fi
randomString="${randomString,,}"
export RANDOM_STRING=$randomString
signedInUserId=$(az ad signed-in-user show --query id --output tsv)
export SINGED_IN_USER_PRINCIPAL=$signedInUserId

#set up parameter file
declare -A REPLACE_TOKENS=(
    [\${WORKSPACE}]=${WORKSPACE}
    [\${LOCATION}]=${LOCATION}
    [\${SINGED_IN_USER_PRINCIPAL}]=${SINGED_IN_USER_PRINCIPAL}
    [\${RANDOM_STRING}]=${RANDOM_STRING}
    [\${AZURE_OPENAI_SERVICE_NAME}]=${AZURE_OPENAI_SERVICE_NAME}
    [\${GPT_MODEL_DEPLOYMENT_NAME}]=${AZURE_OPENAI_GPT_DEPLOYMENT}
    [\${CHATGPT_MODEL_DEPLOYMENT_NAME}]=${AZURE_OPENAI_CHATGPT_DEPLOYMENT}
    [\${USE_EXISTING_AOAI}]=${USE_EXISTING_AOAI}
    [\${AZURE_OPENAI_SERVICE_KEY}]=${AZURE_OPENAI_SERVICE_KEY}
)
parameter_json=$(cat "$DIR/../infra/main.parameters.json.template")
for token in "${!REPLACE_TOKENS[@]}"
do
  parameter_json="${parameter_json//"$token"/"${REPLACE_TOKENS[$token]}"}"
done
echo $parameter_json > $DIR/../infra/main.parameters.json

#make sure bicep is always the latest version
az bicep upgrade

#deploy bicep
az deployment sub what-if --location $LOCATION --template-file main.bicep --parameters main.parameters.json
if [ -z $SKIP_PLAN_CHECK ]
    then
        printInfo "Are you happy with the plan, would you like to apply? (y/N)"
        read -r answer
        answer=${answer^^}
        
        if [[ "$answer" != "Y" ]];
        then
            printInfo "Exiting: User did not wish to apply infrastructure changes." 
            exit 1
        fi
    fi
results=$(az deployment sub create --location $LOCATION --template-file main.bicep --parameters main.parameters.json)

#save deployment output
printInfo "Writing output to infra_output.json"
pushd "$DIR/.."
echo $results > infra_output.json