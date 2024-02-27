#! /bin/bash

set -e

# Colours for stdout
YELLOW='\e[1;33m'
RESET='\e[0m'

usage() {
    cat <<USAGE

    Usage: $0 [-d directory] [-e environment] [-o output] [-p plan name] [-y]

    Options:
        -d, --directory:        directory where to execute plan, defaults to script directory.
        -e, --environment:      where to get environment variables from.
        -o, --output:           file(s) to save the terraform apply output to, only runs terraform output when set.
        -p, --plan-name:        name of the plan, defaults to <basename of the directory>-plan .
        -y:                     if present, will skip the plan verification check.
        -h, --help:             show help.
USAGE
    exit 1
}

printInfo() {
    printf "$YELLOW\n%s$RESET\n" "$1"
}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
PLAN_NAME=""
OUTPUT_FILES=()

while [ "$1" != "" ]; do
    case $1 in
    -d | --directory)
        shift # remove `-d` or `--directory` from `$1`
        DIR=$1
        ;;
    -e | --environment)
        shift # remove `-e` or `--environment` from `$1`
        ENV=$1
        ;;
    -o | --output)
        shift # remove `-o` or `--output` from `$1`
        SET_OUT=1
        continue
        ;;
    -p | --plan-name)
        shift # remove `-p` or `--plan-name` from `$1`
        PLAN_NAME=$1
        ;;
    -y)
        SKIP_PLAN_CHECK=1
        ;;
    -h | --help)
        usage # run usage function on help
        ;;
    *)
        if [[ -n $SET_OUT ]];
        then
            OUTPUT_FILES+=("$1")
            shift # remove file name from `$1`
            continue 
        else
            usage
        fi
        ;;
    esac

    unset SET_OUT # this will end the addition to OUTPUT_FILES
    shift # remove the current value for `$1` and use the next
done

# If plan name is empty, set default
if [[ $PLAN_NAME == "" ]];
then
    PLAN_NAME="$( basename $DIR )-plan"
    printInfo "Plan name is defaulting to $PLAN_NAME";
fi

# If plan name is empty, set default
if [[ -n $ENV ]];
then
    source $ENV
fi

pushd $DIR > /dev/null
# reset the current directory on exit using a trap so that the directory is reset even on error
function finish {
  popd > /dev/null
}
trap finish EXIT

# with -detailed-exitcode the plan will return the following:
# 0 - Succeeded with empty diff
# 1 - Error
# 2 - Succeeded with non-empty diff
set +e
terraform plan -detailed-exitcode -out "$PLAN_NAME"
plan_exit_code=$?
set -e

case $plan_exit_code in
    0)
        printInfo "No changes, exiting..."
        # If output specified then write to output
        if (( ${#OUTPUT_FILES[@]} ));
        then
            printInfo "Writing terraform output to ${OUTPUT_FILES[*]}"
            terraform output -json | tee ${OUTPUT_FILES[*]} > /dev/null
        fi
        exit 0
        ;;
    1)
        exit 1
        ;;
esac

# Run verification checks when not in CI
if [[ -z "${TF_IN_AUTOMATION}" ]];
then 
    # Save plan to txt file for easier verification
    printInfo "Saving plan to $DIR/$PLAN_NAME.tfplan.txt"
    terraform show -no-color "$PLAN_NAME" > "$PLAN_NAME.tfplan.txt"

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
fi

printInfo "Running apply..."
terraform apply -input=false "$PLAN_NAME"

# If output specified then write to output
if (( ${#OUTPUT_FILES[@]} ));
then
    printInfo "Writing terraform output to ${OUTPUT_FILES[*]}"
    terraform output -json | tee ${OUTPUT_FILES[*]} > /dev/null
fi