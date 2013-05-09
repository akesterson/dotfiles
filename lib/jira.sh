#!/bin/bash

. ~/etc/jira.sh

alias jira="/opt/atlassian-cli/jira.sh --server $JIRA --password \"$JIRA_PASS\" --user \"$JIRA_USER\""

function jira_start()
{
    if [ "$1" == "--help" ]; then
	echo "jira_start <issue key>"
	echo
	echo "Starts a work log timer for the given issue. The work log timer"
	echo "can be stopped (and posted) with jira_stop."
	return 1
    fi

    mkdir -p ~/tmp/jira_logs
    date "+%s" > ~/tmp/jira_logs/$1
    echo "Started work on $1"
}

function jira_stop()
{
    if [ "$1" == "--help" ]; then
	echo "jira_stop <issue key> [comment]"
	echo
	echo "Stops the work timer for the given issue and posts the log to the ticket."
	echo "If there is a comment, that will be posted as well."
    fi

    NOW=$(date "+%s")
    THEN=$(cat ~/tmp/jira_logs/$1 2>/dev/null || echo $NOW)
    rm -f ~/tmp/jira_logs/$1
    SPENT=$(expr $(expr $NOW - $THEN) / 60)
    if [ $SPENT -lt 1 ]; then
	echo "Spent less than 1 minutes on $1, will not log work."
	return 0
    fi

    echo "Logging ${SPENT} minutes on $1"
    jira -a addWork \
	--issue $1 \
	--timeSpent "${SPENT}m" \
	--comment "$2"
}

function jira_filter()
{
	if [ "$1" == "--help" ]; then
		echo "jira_filter <filter_name>"
		return 1
	fi

	jira -a getIssueList --filter "$1" |\
		grep "^\"[A-Z]" | \
		grep -v "^\"Key" | \
		sed  	\
			-e s/"\"\""/"\"Unassigned\""/g \
			-e s/"\"P2 - Major (3)\""/"\"$(echo -e '\033[0;31;40m')Major$(echo -e '\033[0m')\""/g  \
			-e s/"\"P3 - Critical (4)\""/"\"$(echo -e '\033[0;31;40m')Critical$(echo -e '\033[0m')\""/g \
			-e s/"\"P[0-9] - \([a-zA-Z]*\) ([0-9])\""/"\"\1\""/g |\
		 cut -d , -f 1,6,7,10,12 |\
		 sed 	\
			-e s/"^\""//g \
			-e s/"\",\""/"\t"/g \
			-e s/"\"$"/""/g \
			-e s/"$"/"\n"/g
}

function jira_link()
{
    if [ "$1" == "--help" ]; then
	echo "jira_link <issue> <link type> <issue>"
	return 1
    fi
    issue="$1"
    link="$2"
    target="$3"

    /opt/atlassian-cli/jira.sh \
	--server $JIRA \
	--user $JIRA_USER \
	--password $JIRA_PASS \
	--action linkIssue \
        --issue $issue \
        --toIssue $target \
        --link "$link"
}

function jira_ticket()
{
    if [ "$1" == "--help" ]; then
	echo "jira_ticket <project> <ticket type> <summary> <description> [<parent> <version> <custom fields>]"
	echo
        echo "Note that custom fields are expected in exactly the same syntax that atlassian-cli expects them."
	return 1
    fi
    project="$1"
    tkt_type="$2"
    summary="$3"
    description="$4"
    parent="--parent=$5"
    version="--fixVersions=$6"
    custom="--custom=$7"

    /opt/atlassian-cli/jira.sh \
	--server $JIRA \
	--user $JIRA_USER \
	--password $JIRA_PASS \
	--action createIssue \
	--project "$project" \
	--type "$tkt_type" \
	--summary "$summary" \
	--description "$description" \
        $custom $version $parent 2>&1 > ~/.$$.jira_ticket
    export JIRATICKET=$(grep -Eo "${project}-[0-9]+" ~/.$$.jira_ticket | head -n 1)
    cat ~/.$$.jira_ticket
    rm -f ~/.$$.jira_ticket
}
