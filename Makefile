all:
	export ISSUER=chris@oracleateam.com; ./simpleca.sh christopher.johnson@oracle.com

clean:
	@rm -f *~
	@rm -f *.key *.crt *.p12 *.jks *.der *.req *.serial
	@echo Clean.
