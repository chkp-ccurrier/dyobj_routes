# dyobj_routes

Version 1
UPDATED 6/12/2018

------------------------------
INSTALL
------------------------------

cp dyobj_routes.sh $CPDIR/bin
chmod 755 $CPDIR/bin/dyobj_routes.sh


------------------------------
RUN
------------------------------
This script is intended to run on a Check Point Firewall

Usage:
  dyobj_routes.sh <options>

Options:
  -o                    Dynamic Object Name (required)
  -i                    network interface (required)
  -a                    action to perform (required) includes:
                              run (once), on (schedule), off (from schedule), stat (status)
  -h                    show help

------------------------------
EXAMPLES
------------------------------
IMPORTANT:  Be sure that the dynamic object you are working with has been created
	    in your security policy and pushed out to the gateway. If not you will
	    be updating an object that will have no effect. Also every object name 
	    is prefaced with "DYOBJ_" by the script.

Activate an object
     dyobj_routes.sh -o myDynObj -i Mgmt -a on

Run Right away
     dyobj_routes.sh -o myDynObj -i eth0 -a run

Deactivate an object
     dyobj_routes.sh -o myDynObj -a off

Get Object status
     dyobj_routes.sh -o myDynObj -a stat

------------------------------
LOGS
------------------------------

A Log of events can be found at $FWDIR/log/route_dynObj.log. 

------------------------------
Change Log
------------------------------

v1 - 6/12/18  - 1st version


------------------------------
Author
------------------------------
CB Currier - ccurrier@checkpoint.com

