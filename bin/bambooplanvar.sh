#!/bin/bash

# LOL
#. ~/etc/bamboo.sh

BAMBOO=$(echo $BAMBOO | sed s/'\/$'//)

function bambooplanvar_get_existing_id()
{
    cat /tmp/$$.html | grep -Eo "^<input type=\"text\" name=\"key_[0-9]+\" value=\"$1\"" 2>/dev/null | cut -d _ -f 2 | cut -d \" -f 1
}

function main()
{
    PLAN="$1"

    curl --user "$BAMBOO_USER:$BAMBOO_PASSWORD" $BAMBOO/chain/admin/config/configureChainVariables.action?buildKey="$PLAN"\&os_authType=BASIC >/tmp/$$.html 2>/dev/null

    if [ $? -ne 0 ] || [ "$(grep -i 'page not found' /tmp/$$.html)" != "" ]; then
	# hmm ... is it a branch? They use different URLs.
	curl --user "$BAMBOO_USER:$BAMBOO_PASSWORD" $BAMBOO/branch/admin/config/editChainBranchVariables.action?buildKey="$PLAN"\&os_authType=BASIC > /tmp/$$.html 2>/dev/null
    fi

    if [ "$2" == "" ]; then
	echo "{}" > /tmp/$$.json
	for name in $(cat /tmp/$$.html | grep -E "^<input type=\"text\" name=\"key_[0-9]+\"" | cut -d = -f 4 | cut -d \" -f 2)
	do
	    EXISTINGID=$(bambooplanvar_get_existing_id $name)
	    VAL=$(cat /tmp/$$.html | grep -E "^<input type=\"text\" name=\"value_$EXISTINGID\"" | cut -d = -f 4 | cut -d \" -f 2)
	    /opt/sa_utils/bin/jsontool --file /tmp/$$.json --in-place set $name "\"$VAL\""
	done
	cat /tmp/$$.json
	return
    elif [ "$2" == "-" ] || [ -f "$2" ]; then
	if [ -f "$2" ]; then
	    JSON=$(cat $2)
	else
	    JSON=$(cat)
	fi
	for key in $(echo "$JSON" | /opt/sa_utils/bin/jsontool iterate key)
	do
	    $BASH_SOURCE $PLAN $key "$(echo $JSON | /opt/sa_utils/bin/jsontool get $key)"
	done
    elif [ "$2" != "" ]; then
	VAR="$2"
	VAL="$3"

	EXISTINGID=$(bambooplanvar_get_existing_id $VAR)
	if [ "$EXISTINGID" != "" ]; then
	    curl -X POST --user "$BAMBOO_USER:$BAMBOO_PASSWORD" ${BAMBOO}/build/admin/ajax/updatePlanVariable.action -d os_authType=BASIC -d planKey=$PLAN -d variableId=$EXISTINGID -d variableKey="$VAR" -d variableValue="$VAL" >/dev/null 2>&1
	    exit $?
	else
	    curl -X POST --user "$BAMBOO_USER:$BAMBOO_PASSWORD" ${BAMBOO}/build/admin/ajax/createPlanVariable.action -d buildKey="$PLAN" -d os_authType=BASIC -d variableKey="$VAR" -d variableValue="$VAL" > /dev/null 2>&1
	    exit $?
	fi
    fi
    rm -f /tmp/$$.*
}

if [ "$1" == "--help" ]; then
	echo "bambooplanvar.sh <PLANKEY> <VARNAME> <VARVALUE>"
	echo "        ... sets a single variable to a value on a plan."
	echo "bambooplanvar.sh <PLANKEY>"
	echo "        ... gives a json dict on stdout of all variables for that plan."
	echo "bambooplanvar.sh <PLANKEY> -"
	echo "        ... sets a json dict from stdin of all variables for that plan."
	exit 1
fi

main "$1" "$2" "$3"
