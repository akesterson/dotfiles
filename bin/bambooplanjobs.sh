#!/bin/bash

if [ "$1" == "--help" ]; then
	cat << EOF
bambooplanjobs.sh <plan key>
	... fetch a JSON document describing all the jobs in this plan. TASKS ARE NOT DESCRIBED, though an empty json dict is printed in their place.
bamboostagejobs.sh <plan key> -
	... take a document from standard input and set up jobs in the given plan key to match. THIS SHOULD ONLY BE USED ON PLANS WITH EMPTY STAGES.
EOF
	exit 0
fi

if [ "$2" != "-" ]; then
	(\
		echo -n '{' ; \
		echo -n $(\
			curl -X GET --user "$BAMBOO_USER:$BAMBOO_PASSWORD" ${BAMBOO}chain/admin/config/defaultStages.action?buildKey=$1 \
			-d os_authType=BASIC 2>/dev/null | \
				grep -E 'data-job-key=|li id="stage-[0-9]+"' |\
				(\
					curstage=""; 
					while read LINE; do 
						newstage=$(echo $LINE | grep -Eo 'li id="stage-[0-9]+"' | cut -d \- -f 2 | cut -d \" -f 1); \
						if [ "$newstage" != "" ] && [ "$newstage" != "$curstage" ]; then \
							if [ "$curstage" != "" ]; then \
								echo '],' ; \
							fi ; \
							echo "\"$newstage\": [ " ; \
						curstage="$newstage"; \
						else \
							echo "$LINE"; \
						fi; \
					done) |\
				sed \
					-e s/'id="\([a-zA-Z-]*\)"\s*class='/'id="\1" title="" class='/g \
					-e s/'.*id="job-'$1'-\([A-Z]*\)\s*"\s*title="\(.*\)"\s*class="\([a-z]*\)\s*".*'/'{"name": "\1", "title": "\2", "state": "\3", "tasks": {}, "requirements": {}, "artifacts": {}},'/g ; \
				echo ']' ; \
				echo '}' \
			) |\
		sed -e s/'},\s*}'/'}}'/g -e s/'},\s*]'/'}]'/g ; \
		echo ) | /opt/sa_utils/bin/jsontool get
fi

exit 0
