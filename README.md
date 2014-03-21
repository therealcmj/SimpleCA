SimpleCA
========

A dead simple Certificate Authority 

Further Information
========
This is the CA script that I wrote for my own purposes.

I talked about the script at
http://fusionsecurity.blogspot.com/2011/04/dead-simple-certificate-authority-for.html

And then after adding JKS support at
http://fusionsecurity.blogspot.com/2011/08/updated-dead-simple-certificate.html

I'm moving this to Github so that it's under source control and available to others in a better way.

The Original Blog Post
========
I don't know about you, but I know I'd rather spend an hour writing a script to automate something than 30 minutes figuring out how to use an existing but annoying/terrible tool. I do that not because I am a glutton for punishment, but because I know I'll have to use that terrible tool again in the future and I won't remember how to use it anyway.

So when I needed certificates for a test environment I checked out OpenSSL's built in CA tool, quickly decided against using it, and then wrote my own simpler tool. 

Usage Instructions
========
 To use:

Make a directory to contain the script and the keys and certs it will generate
put this code into a file in that directory. I called it simpleca.sh, but use whatever name you like
run it

The script takes one or more parameters that specify the CN of the cert you want it to generate. So

	$ ./simpleca.sh myserver.mydomain.com

will make a cert for myserver.mydomain.com. It will also take more than one CN on the command line, so

	$ ./simpleca.sh myserver.mydomain.com login.mydomain.com

will make a certificate for myserver.mydomain.com and another one for login.mydomain.com. 

You can also make certificates for users - just put the username as the argument. Like so:
	$ ./simpleca.sh myserver.mydomain.com christopher.johnson@oracle.com

Plans
========
I wrote this for my own purposes so it has some warts.

I'll probably keep making cleanups to it over time but not on any sort of regular schedule.
