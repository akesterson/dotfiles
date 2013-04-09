#!/bin/bash

. ~/etc/jira.sh

alias jira="/opt/atlassian-cli/jira.sh --server $JIRA --password \"$JIRA_PASS\" --user \"$JIRA_USER\""

function jira_certify_arch()
{
	if [ "$1" == "--help" ]; then
		echo "jira_certify_arch <application> <build>"
		return 1
	fi
	for os in el5 el6; 
	do 
		BUILDCERT=$(jira_buildcert $1 $2 $os architecture-testing-$os architecture-$os x86_64 | grep -Eo "BUILDCERT-[0-9]+" | head -n 1)
		jira -a progressIssue --issue $BUILDCERT --step Certify
	done
	printf "promote_application_package\nrefresh_repos" |\
		ssh -q 10.32.4.200 "cat | sudo /opt/mrresetti/bin/mrresetti - --conf /etc/mrresetti/config.yaml"
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
			-e s/" - Sev [0-9] ([0-9])"//g \
			-e s/"\"Major\""/"\"$(echo -e '\033[0;31;40m')Major$(echo -e '\033[0m')\""/g  \
			-e s/"\"Critical\""/"\"$(echo -e '\033[0;31;40m')Critical$(echo -e '\033[0m')\""/g |\
		 cut -d , -f 1,6,7,10,12 |\
		 sed 	\
			-e s/"^\""//g \
			-e s/"\",\""/"    "/g \
			-e s/"\"$"/""/g \
			-e s/"$"/"\n"/g
}

function jira_buildcert()
{
	if [ "$1" == "--help" ]; then
	    echo "jira_buildcert <package> <version> [<os> <src repo> <dst repo> <arch>]"
	    return 1
	fi
	package=$1
	version=$2
        os=$3
	src=$4
	dest=$5
	arch=$6
	if [ "$os" == "" ]; then
	    os="Default"
	fi
	if [ "$src" == "" ]; then
            src="tsysrepo-testing"
        fi
	if [ "$dest" == "" ]; then
	    dest="tsysrepo"
	fi
	if [ "$arch" == "" ]; then
	    arch="noarch"
	fi

	/opt/atlassian-cli/jira.sh \
	    --assignee Devops \
	    --server $JIRA \
	    --password $JIRA_PASS \
	    --user $JIRA_USER \
	    --action createIssue \
	    --project BUILDCERT \
	    --type "Build Certification" \
	    --summary "Please certify ${package}-${version}." \
	    --comment "Please certify ${package}-${version}." \
	    --custom customfield_10251:${package},customfield_10252:${version},customfield_10880:${src},customfield_10881:${dest},customfield_10882:${arch},customfield_10883:$os
}

function jira_cr()
{
    if [ "$1" == "--help" ]; then
	echo "jira_cr <summary> <description> <duedate(DD/MMM/YY HH:MM am|pm> <environment (UAT|Prod)> <version>"
	return 1
    fi
    summary="$1"
    description="$2"
    duedate="$3"
    environment="$4"
    version="$5"

    /opt/atlassian-cli/jira.sh \
	--server $JIRA \
	--user $JIRA_USER \
	--password $JIRA_PASS \
	--action createIssue \
	--components "SA Code Deployment" \
	--project CR \
	--type "Task" \
	--summary "$summary" \
	--description "$description" \
	--custom customfield_10146:Low,customfield_10110:Loyalty,customfield_10147:"DevOps Architecture Team",customfield_10001:Routine,customfield_10002:"$duedate",customfield_10010:$environment,customfield_10150:$(whoami) \
	--fixVersions "$version"
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
        $custom $version $parent
}
