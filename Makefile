bashfile=$(shell if [ "$$(uname)" == "Darwin" ]; then echo ~/.bash_profile ; else echo ~/.bashrc ; fi)
CLI_VERSION=330

install:
	echo "Installing version 3.3.0 of atlassian-cli, edit the Makefile if this isn't what you want..."
	wget https://marketplace.atlassian.com/download/plugins/org.swift.atlassian.cli/version/${CLI_VERSION} -O cli.zip
	unzip cli.zip
	mv atlassian-cli-3.3.0 /opt/atlassian-cli
	mkdir -p ~/bin/
	mkdir -p ~/lib/
	mkdir -p ~/etc/
	cp bin/* ~/bin/
	cp lib/* ~/lib/
	cp etc/* ~/etc/
	echo "$$PATH" | grep -E ':~/bin:|:~/bin$$' >/dev/null 2>&1 ; \
	if [ $$? -ne 0 ]; then \
		echo 'export PATH=~/bin:$$PATH' >> $(bashfile) ; \
	fi
	echo 'source ~/lib/jira.sh' >> $(bashfile)
	echo 'source ~/lib/bamboo.sh' >> $(bashfile)
	echo 'source ~/lib/hg.sh' >> $(bashfile)
	echo 'source ~/lib/misc.sh' >> $(bashfile)
