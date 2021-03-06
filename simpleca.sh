#!/bin/bash

#  ____    _                       _             ____      _
# / ___|  (_)  _ __ ___    _ __   | |   ___     / ___|    / \
# \___ \  | | | '_ ` _ \  | '_ \  | |  / _ \   | |       / _ \
#  ___) | | | | | | | | | | |_) | | | |  __/   | |___   / ___ \
# |____/  |_| |_| |_| |_| | .__/  |_|  \___|    \____| /_/   \_\
#                         |_|
#
# a simple Certificate Authority script
#
# Copyright 2010-2021
# Chris Johnson christopher.johnson@oracle.com
# Oracle
#

# License agreement:
# ------------------
# This script is intended as a simple tool for my own purposes.
#
# Unfortunately that means that it comes with NO warranties and NO support.
#
# That said if you find it useful or run into problems please do send me an
# email or open an issue on Github and I'll do what I can to help.

# Load config file, or create a new one from template if not found
LoadConfigFile() {
    local cfgFileName="simpleca.cfg"

    # Config file template
    [ -f "./$cfgFileName" ] || {
        #  __       __       __  __         __  ___  __
        # |__) |   |_   /\  (_  |_    |\ | /  \  |  |_
        # |    |__ |__ /--\ __) |__   | \| \__/  |  |__
        #
        # To change the configueation in your environment edit simpleca.cfg!
        #                                                      ------------
        # The text below is only a config file template.
        # Editing these lines will only change the template and --> WILL NOT <--
        # change your settings!
        #
        cat >"./$cfgFileName" <<"__ENDS__"
#======BEGINS CONFIGURATION FILE=====================================
# once you have edited the settings to your liking uncomment this line
# CONFIGURED=TRUE

# Choose a passphrase to protect the .key and .jks file generated by the script.
# You should probably use a better passphrase than this but there's no harm
# in leaving it as is.
PASSPHRASE=ABcd1234

# the next 3 settings use OpenSSL's format for DN components:
# /C=     Country
# /ST=    State
# /L=     Location
# /O=     Organization
# /OU=    Organizational Unit
# /CN=    Common Name
#
# if you don't know what this means just leave the remaining settings as is.
#
# Remember these rules:
# * you must start each portion with /
# * case is important - /C= works but /c= will not
# * x509 tools almost always expect a CN= somewhere

# If not specified the cert issuer will be "root@" + the local hostname
# You can override this here and remove or add anything you want
CERT_ISSUER="/C=US/O=Oracle/OU=A-Team/OU=Test Cert Authority/CN=root@`hostname`"

# The script allows for two separate formats for certificate DNs
# 1: SSL server certificates used (for example) by https web servers
# 2: "User" certificates used for 2-way SSL
#
# When constructing cert DNs %1 will be replaced with the CN specified on the
# command line.

# Server Cert DN format:
CERTDN_FORMAT_SERVER='/C=US/O=Oracle/OU=Server Cert Authority/CN=%1'

# User Cert DN format:
CERTDN_FORMAT_USER='/C=US/O=Oracle/OU=A-Team/CN=%1'

# location of OpenSSL configuration file
# if you are not sure what value to use then run "openssl version -d"
# copy the value from there and append "openssl.cnf"
# for example:
#  $ openssl version -d
#  OPENSSLDIR: "/usr/local/etc/openssl"
#
# then the setting should be OPENSSL_CONF="/usr/local/etc/openssl/openssl.cnf"
OPENSSL_CONF="/etc/ssl/openssl.cnf"

# You shouldn't need to edit this
CONFIG_VERSION=2

# debug is really just for me to get more info as the script runs
# it probably won't do you any good
DEBUG_SIMPLECA=FALSE

#======ENDING CONFIGURATION FILE=====================================
__ENDS__
        logMsg "Config file '$cfgFileName' not found."
        logMsg "A sample with reasonable defaults has been created for you."
        logMsg "Please edit that file then run this script again."
        logMsg "Helpful information is included within the file itself."
        abortMsg "Configuration incomplete."
    }
    . "./$cfgFileName" || abortMsg "Error loading $cfgFileName file"
    # IMPORTANT: If you edit the above config template to add a new
    # setting, you should increment CONFIG_VERSION in the template above
    # and the version number below
    #
    # If you make other edits which don't involve adding/removing
    # a setting, such as changing instructional comments, you don't
    # need to increment the config version number.
    local expectedConfigVersion=2
    [ "$CONFIG_VERSION" == "$expectedConfigVersion" ] || {
            logMsg "ERROR: You $cfgFileName has the wrong version"
            logMsg "Expected version ${expectedConfigVersion}, got version ${CONFIG_VERSION}"
            logMsg "Most likely it was created with a different version of this script"
            logMsg "To fix this, rename or remove your $cfgFileName file"
            logMsg "Then run this script again to create a new one."
            abortMsg "Configuration version mismatch - aborting."
    }
    [ "$CONFIGURED" = "TRUE" ] || {
            logMsg "ERROR: Please follow instructions in $cfgFileName file!"
            logMsg "       If you get stuck delete the file then run this script again."
            logMsg "       A fresh config file will automatically be created."
            abortMsg "Configuration incomplete - aborting."
    }
}

debugMsg() {
    if [ "$DEBUG_SIMPLECA" == "TRUE" ]; then
        logMsg "$*"
    fi
}
logMsg() {
    #echo 1>&2 "[$(date)] $*"
    echo 1>&2 "$*"
}

# Abort with an error
abortMsg() {
    logMsg "ERROR: $*"
    exit 1
}

CABASEfile=simpleca
CACRTfile=$CABASEfile.crt
CAKEYfile=$CABASEfile.key
CAP12file=$CABASEfile.p12
CAJKSfile=$CABASEfile.jks

createderfiles() {
    debugMsg Creating .der files for \"$1\"
    
    openssl pkcs8 -topk8 -nocrypt -in "$1".key -inform PEM -out "$1".key.der -outform DER 2> /dev/null
    openssl x509 -in "$1".crt -inform PEM -out "$1".crt.der -outform DER 2> /dev/null
}


# better safe than sorry
umask 077

# figure out where the script is on disk
SCRIPTDIR=`dirname $0`

# find keytool in our path
KEYTOOL=`which keytool`
if [ "$KEYTOOL" == "" ] ; then
    logMsg "keytool command not found. Update your path if you want"
    logMsg "to create JKS files as well as PEM format files."
fi

# if you're running this from somewhere else...
if [ $SCRIPTDIR != "."  -a  $SCRIPTDIR != $PWD ]; then
    # then CD to that directory
    cd $SCRIPTDIR
    if [ "$KEYTOOL" == "" ]; then
        debugMsg "Output files (.crt, .key) will be placed in $PWD"
    else
        debugMsg "Output files (.crt, .key, .der and .jks) will be placed in $PWD"
    fi
fi

# OK, now try to load the config file
LoadConfigFile

# TODO: add additional sanity checks on inputs

if [ ! -e ${OPENSSL_CONF} ]; then
  logMsg "OpenSSL config file not found in expected location:"
  logMsg "$OPENSSL_CONF"
  logMsg ""
  logMsg "Please update config file and then run again."
  exit 1
fi

if [ ! -e $CACRTfile -o ! -e $CAKEYfile ]; then
    rm -f $CACRTfile $CAKEYfile $CAP12file
    logMsg "Creating cert authority key & certificate"
    openssl req -newkey rsa:4096 -keyout $CAKEYfile -nodes -x509 -days 3650 -out $CACRTfile -subj "${CERT_ISSUER}" 2> /dev/null
fi

if [ "$KEYTOOL" != "" ] ; then
    if [ ! -e $CACRTfile.der -o ! -e $CAKEYfile.der -o ! -e $CAJKSfile ]; then
        # convert to der
        createderfiles $CABASEfile
        
        # we actually don't need/want the $CAKEYfile.der but there's no
        # harm in leaving it around since the .key file is here anyway
        debugMsg "Creating $CAJKSfile"

        # import the CA certificate into the JKS file marking it as trusted
        keytool -import -noprompt -trustcacerts \
                -alias $CABASEfile \
                -file $CACRTfile.der \
                -keystore $CAJKSfile \
                -storetype JKS \
                -storepass $PASSPHRASE \
                2> /dev/null
    fi
fi

if [ $# -eq 0 ] ; then
    
    echo "This script creates one or more certificates."
    echo "Specify certificate CNs on the command line."
    echo ""
    echo "Usage: "
    echo "    `basename $0` <certcn> [certcn [...]]"
    echo ""
    echo "By default server certificates will be issued."
    echo "To issue user certificates instead add -u before one or more CNs"
    echo "For example:"
    echo "    `basename $0` -u <certcn> [certcn [...]]"
    echo ""
    exit -1
fi

# "Server" certs are the default
CERT_TYPE=SERVER

for certCN in "$@" ; do
    if [ "$certCN" == "-u" ]; then
        CERT_TYPE=USER
    # an undocumented argument to switch back to server certs
    elif [ "$certCN" == "-s" ]; then
        CERT_TYPE=SERVER
    else
        logMsg $CERT_TYPE certificate for CN \"$certCN\"
        logMsg ===============================================================
        
        KEY="$certCN".key
        CRT="$certCN".crt
        REQ="$certCN".req
        P12="$certCN".p12
        JKS="$certCN".jks

        # files we can delete later
        KEYDER="$KEY".der
        CRTDER="$CRT".der

        if [ -e "$CRT" ] ; then
            
            logMsg "ERROR!"
            logMsg ""
            logMsg "Certificate file $CRT already exists"
            logMsg ""
            logMsg "If you wish to recreate a certificate you must delete any"
            logMsg "preexisting files for that CN before running this script."
            logMsg ""
        else
            if [ -e "$REQ" ] ; then
                debugMsg Processing existing cert request $certCN.req
            else
                debugMsg Generating CSR for \"$certCN\"
                if [ "$CERT_TYPE" == "USER" ]; then
                    CERTDN="${CERTDN_FORMAT_USER/\%1/$certCN}"
                else
                    CERTDN="${CERTDN_FORMAT_SERVER/\%1/$certCN}"
                fi
                debugMsg Cert DN: ${CERTDN}

                openssl req \
                    -newkey rsa:4096 \
                    -keyout "$KEY" \
                    -nodes \
                    -days 365 \
                    -out "$REQ" \
                    -subj "${CERTDN}" \
                    -reqexts ${CERT_TYPE} \
                    -addext "subjectAltName = DNS:${certCN}" \
                    -config <(cat ${OPENSSL_CONF} <(printf "[SERVER]\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:${certCN}\n[USER]\nextendedKeyUsage=clientAuth\n")) 2> /dev/null

            fi

            # at this point we have a cert request file, but the cert is not signed by the CA
            openssl x509 -req -in "$REQ" -out "$CRT" -days 365 -extensions ${CERT_TYPE} -extfile <(cat ${OPENSSL_CONF} <(printf "[CA_default]\ncopy_extensions=copy\n[SERVER]\nextendedKeyUsage=serverAuth\n[USER]\nextendedKeyUsage=clientAuth\n")) -CA "$CACRTfile" -CAkey "$CAKEYfile" -CAcreateserial -CAserial $CABASEfile.serial -days 365 2> /dev/null
            # We now have a req, key and crt files which contain PEM format
            # x.509 certificate request
            # x.509 private key
            # x.509 certificate
            # respectively.

            logMsg "Certificate created."
            logMsg ""
            logMsg 'Certificate information:'
            openssl x509 -in "$CRT" -noout -issuer -subject -serial

            if [ ! -e "$KEY" ] ; then
                logMsg No private key available - no .p12 or JKS file will be generated
            else
                # generate a pkcs12 file with the private key in it
                openssl pkcs12 -export -in "$CRT" -inkey "$KEY" -certfile "$CACRTfile" -name "$certCN" -out "$P12" -password pass:$PASSPHRASE -nodes 2> /dev/null
                
                # if we have keytool we also need to create a jks file
                if [ "$KEYTOOL" != "" ] ; then
                    debugMsg ""
                    debugMsg "Creating JKS file:"
                    createderfiles "$certCN"
                    
                    debugMsg "Creating $JKS"
                    # step 1: copy the CA keystore into the new one
                    cp "$CAJKSfile" "$JKS"
                    
                    # step 2: take the pkcs12 file and import it right into a JKS
                    keytool -importkeystore \
                            -deststorepass $PASSPHRASE \
                            -destkeypass $PASSPHRASE \
                            -destkeystore "$JKS" \
                            -srckeystore "$P12" \
                            -srcstoretype PKCS12 \
                            -srcstorepass $PASSPHRASE \
                            -alias "$certCN" 2> /dev/null
                fi
            fi
            logMsg ""
            logMsg "Files:"
            ls -l "${certCN}".*
            logMsg ""
        fi
    fi
done
