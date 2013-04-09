#!/bin/bash

BUILDKEY=$1
HGURL=$2
BRANCH=$3
EXCLUDEREGEX=${4:-}

if [ "$1" == "--help" ]; then
	echo "bambooplanhgrepo.sh <buildkey> <hgurl> <branch> [<changeset exclusion regex>]"
	echo ""
	echo "This script is rather dumb and probably dangerous."
	echo "Dont use it unless you already know what the arguments mean"
	echo "and are fully prepared to deal with the fallout of your"
	echo "projects' repositories getting slammed/fubared/reordered."
	echo
	echo "You have been warned."
	exit 1
fi

. ~/etc/bamboo.sh

curl --cookie-jar ~/.bamboo.cookies --user "$BAMBOO_USER:$BAMBOO_PASSWORD" ${BAMBOO}'/chain/admin/config/editChainRepository.action?os_authType=BASIC&buildKey'=$1 2>/dev/null > /tmp/$$.html
REPOID=$(cat /tmp/$$.html | grep "editRepository.action" | grep -Eo "repositoryId=[0-9]+" | cut -d = -f 2)

curl -X POST --user "$BAMBOO_USER:$BAMBOO_PASSWORD" \
	${BAMBOO}/chain/admin/config/updateRepository.action \
	--cookie-jar ~/.bamboo.cookies \
        -F os_authType=BASIC \
	-F "planKey=$BUILDKEY" \
	-F repositoryId=$REPOID \
	-F selectedRepository=com.atlassian.bamboo.plugins.atlassian-bamboo-plugin-mercurial:hg \
	-F selectFields=selectedRepository \
	-F repositoryName=Mercurial \
        -F "repository.hg.repositoryUrl=$HGURL" \
	-F repository.hg.username= \
	-F repository.hg.authentication=PASSWORD \
	-F selectFields=repository.hg.authentication \
	-F selectFields=repository.hg.authentication \
	-F temporary.hg.password.change=true \
	-F temporary.hg.password= \
	-F checkBoxFields=repository.hg.ssh.compression \
	-F temporary.hg.ssh.key.change=true \
	-F "temporary.hg.ssh.keyFromFile=;filename=;type=application/octet-stream" \
	-F temporary.hg.ssh.passphrase.change=true \
	-F temporary.hg.ssh.passphrase= \
	-F repository.hg.commandTimeout=180 \
	-F checkBoxFields=repository.hg.verbose.logs \
	-F checkBoxFields=repository.hg.noRepositoryCache \
	-F checkBoxFields=repository.common.quietPeriod.enabled \
	-F repository.common.quietPeriod.period=10 \
	-F repository.common.quietPeriod.maxRetries=5 \
	-F filter.pattern.option=none \
	-F selectFields=filter.pattern.option \
	-F filter.pattern.regex= \
	-F "changeset.filter.pattern.regex=$EXCLUDEREGEX" \
	-F selectedWebRepositoryViewer=bamboo.webrepositoryviewer.provided:noRepositoryViewer \
	-F selectFields=selectedWebRepositoryViewer \
	-F webRepository.genericRepositoryViewer.webRepositoryUrl= \
	-F webRepository.genericRepositoryViewer.webRepositoryUrlRepoName= \
	-F webRepository.hg.scheme=bitbucket \
	-F selectFields=webRepository.hg.scheme \
	-F webRepository.stash.url= \
	-F webRepository.stash.project= \
	-F webRepository.stash.repositoryName= \
	-F webRepository.fisheyeRepositoryViewer.webRepositoryUrl= \
	-F webRepository.fisheyeRepositoryViewer.webRepositoryRepoName= \
	-F webRepository.fisheyeRepositoryViewer.webRepositoryPath= \
	-F bamboo.successReturnMode=json-as-html \
	-F decorator=nothing \
	-F confirm=true

rm -f /tmp/$$.html
