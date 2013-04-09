#!/bin/bash

if [ "$1" == "--help" ]; then
	cat << EOF
bambooplanstages.sh <plan id>
	... print a JSON object describing the name, ID, index (build order) and description of each stage in a plan.
bambooplanstages.sh -
	... take a JSON object on standard input, and load it into an EMPTY plan. THIS WILL NOT WORK ON A PLAN WITH EXISTING STAGES.
EOF
	exit 0
fi

JSONTOOL=${JSONTOOL:-/opt/sa_utils/bin/jsontool}

if [ "$2" != "-" ]; then
	( echo -n '[' ; \
		echo -n $( \
			curl -X GET --user "$BAMBOO_USER:$BAMBOO_PASSWORD" ${BAMBOO}chain/admin/config/defaultStages.action?buildKey=PUPPET-PUPPET -d os_authType=BASIC 2>/dev/null | \
			grep -E -A 3 'li id="stage_[0-9]+"' | \
			grep -E "^<li id|<dt>.*</dt>" | \
			sed s/'^\s*'//g | \
			paste - - | (\
				idx=0; \
				while read LINE ; \
				do \
					echo "<idx>$idx</idx>$LINE"; \
					idx=$((idx + 1)); \
				done) | \
			sed \
				-e s/'\s*<span class="icon icon-stage-manual" title="Manual stages require user interaction in order to execute"><span>Manual stages require user interaction in order to execute<\/span><\/span>'/'<manual>true<\/manual>'/g \
				-e s/'\(.*\)<\/span>\(<\/dt>.*\)'/'\1<\/span><manual>false<\/manual>\2'/ \
				-e s/'\(.*\)\([a-zA-Z0-9_-\s]\)\(<\/dt>.*\)'/'\1\2<span><\/span><manual>false<\/manual>\3'/ \
                               -e s/'^<idx>\([0-9]*\)<\/idx><li id="stage_\([0-9]*\)".*<dt>\(.*\)<\/dt>'/'{"name": "\3", "id": \2, "idx": \1},'/g \
                               -e s/'^{"name":\s*"\(.*\)\s*<span>\(.*\)<\/span>\s*<manual>\([a-z]*\)<\/manual>\s*", "id": \([0-9]*\), "idx": \([0-9]*\)},'/'{"name": "\1", "description": "\2", "manual": \3, "id": \4, "idx": \5},'/g |\
			tr '\n' ' '); \
		echo -n ']' ) | sed s/"},\s*]"/"}]"/g | /opt/relman/bin/relman --no-connect print '//' -

else
	# Weehaw, let's make some stages
	cat | $JSONTOOL iterate value | while read STAGE;
	do
		# WHY OH GOD WHY EXPLAIN IT TO ME JESUS ?!?!
		STAGE=$(echo "$STAGE" | /opt/sa_utils/bin/yaml2json | $JSONTOOL get --ugly);
		# --------------
		curl -X POST --user "$BAMBOO_USER:$BAMBOO_PASSWORD" \
			${BAMBOO}chain/admin/ajax/createStage.action \
			-d returnUrl= \
			-d stageName="$(echo $STAGE | $JSONTOOL get name)" \
			-d stageDescription="$(echo $STAGE | $JSONTOOL get description)" \
			-d checkBoxFields=stageManual \
			-d stageManual=$(echo "$STAGE" | $JSONTOOL get manual) \
			-d confirm=true \
			-d decorator=nothing \
			-d bamboo.successReturnMode=json \
			-d os_authType=BASIC \
			-d buildKey=$1
		echo
	done
fi
exit 0
