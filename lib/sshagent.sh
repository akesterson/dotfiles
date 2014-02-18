#!/bin/bash

function sshagent
{
    if [[ -e ~/.ssh-agent ]]; then
	. ~/.ssh-agent
	( ps ax | grep -E '^\s*'${SSH_AGENT_PID} >/dev/null 2>&1) && return 0
	echo "ssh-agent file exists but pid is gone"
    fi
    ssh-agent > ~/.ssh-agent
}
