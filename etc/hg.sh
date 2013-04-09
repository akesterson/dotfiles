#!/bin/bash

PATCHREPO=http://10.32.4.43:9999/$(whoami)/patches
PATCHSPEC=%{TICKET}/%{PROJECT}/patch
SERIESSPEC=%{TICKET}/series
CHECKOUTSPEC=/home/akesterson/source/tsys/wip/%{BASENAME}-%{TICKET}
