#!/bin/bash

PATCHREPO=http://bitbucket.org/$(whoami)/patches
PATCHSPEC=%{TICKET}/%{PROJECT}/patch
SERIESSPEC=%{TICKET}/series
CHECKOUTSPEC=${HOME}/%{BASENAME}-%{TICKET}
