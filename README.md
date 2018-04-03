SimpleCA
========

A dead simple Certificate Authority

Further Information
===================
This is the CA script that I wrote for my own purposes.

Getting Started
===============

Clone this repo, cd into the directory, and then run ./simpleca.sh.

The first time you run the script it will create a configuration file named
simpleca.cfg. Edit that file to your liking (following the instructions
contained within it), and then run ./simpleca.sh again.

A CA certificate will be created for you and placed in simpleca.crt.

If Java's keytool command is found in the path a JKS file (named simplecrt.jks)
will also be created.

You can import either of those into your trust store, though how and why to do
that is beyond the scope of this readme.

Usage:
======

The script takes one or more parameters that specify the CN of the cert you want it to generate.

This command:

	$ ./simpleca.sh myserver.mydomain.com

will make a certificate for myserver.mydomain.com.

You can also specify more than one CN on the command line.

This command:

	$ ./simpleca.sh myserver.mydomain.com login.mydomain.com

will make a certificate for myserver.mydomain.com and another one for login.mydomain.com.

The script puts the generated private key, request (CSR), and certificate in the same directory in files
named .key, .req, .crt, .jks, and a number of other forms for other purposes.

For example running it with "myserver.mydomain.com" will generate the following files:
- myserver.mydomain.com.crt
- myserver.mydomain.com.crt.der
- myserver.mydomain.com.jks
- myserver.mydomain.com.key
- myserver.mydomain.com.key.der
- myserver.mydomain.com.p12
- myserver.mydomain.com.req


You can also make certificates for users.

NOTE: older versions of this script allowed you to just put a "username" as the argument.
      But this version introduces the certificate extension that specifies the cert's purpose.
	  As a result when you want a user certificate you MUST explicitly tell it that by using the
	  argument "-u".

Like so:
	$ ./simpleca.sh -u christopher.johnson@oracle.com sterling.mallory.archer@cia.gov

This will make TWO user certificates - one for christopher.johnson@oracle.com and one for the world's most dangerous spy.

And finally you can also use this script to process certificate signing requests (CSR) generated elsewhere.
Simply generate the CSR as normal, drop it in the directory with the extension .req, and run the script
with the name on the command line as normal:

		bash-3.2$ ls -l myserver.mydomain.com.*
		-rw-------  1 cmj  staff  688 Apr  2 22:12 myserver.mydomain.com.req
		
		bash-3.2$ ./simpleca.sh myserver.mydomain.com
		SERVER certificate for CN "myserver.mydomain.com"
		===============================================================
		Certificate created.
		Certificate information:
		issuer= /C=US/O=Oracle/OU=A-Team/OU=Test Cert Authority/CN=root@Chriss-MBP.lan
		subject= /C=US/O=Oracle/OU=Server Cert Authority/CN=myserver.mydomain.com
		serial=D337621D4B6DCF52
		No private key available - no .p12 or JKS file will be generated

		Files:
		-rw-------  1 cmj  staff  883 Apr  2 22:13 myserver.mydomain.com.crt
		-rw-------  1 cmj  staff  688 Apr  2 22:12 myserver.mydomain.com.req

		bash-3.2$ ls -l myserver.mydomain.com.*
		-rw-------  1 cmj  staff  883 Apr  2 22:13 myserver.mydomain.com.crt
		-rw-------  1 cmj  staff  688 Apr  2 22:12 myserver.mydomain.com.req
		bash-3.2$

Plans
=====
I wrote this for my own purposes so it has some warts.

I'll probably keep making cleanups to it over time but not on any sort of regular schedule.
