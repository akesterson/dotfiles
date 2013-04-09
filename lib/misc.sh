function emacstmp()
{
	rm -f /tmp/$$.emacstmp
	(emacsclient -t /tmp/$$.emacstmp &)
	while [ -e /proc/$!/status ]; 
	do
		sleep 1s
	done
	cat /tmp/$$.emacstmp
}

function vimcat()
{
	rm -f /tmp/$$.vimcat
	vim /tmp/$$.vimcat
	cat /tmp/$$.vimcat
}
