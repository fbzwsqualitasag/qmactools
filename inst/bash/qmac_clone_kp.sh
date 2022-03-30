#!/bin/bash
#' ---
#' title: Clone KP Database
#' date:  2022-03-28 16:33:57
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless cloning of kp database
#'
#' ## Description
#' Clone a given KP database
#'
#' ## Details
#' Copy a given source kp database to a local version
#'
#' ## Example
#' ./qmac_clone_kp.sh
#'
#' ## Set Directives
#' General behavior of the script is driven by the following settings
#+ bash-env-setting, eval=FALSE
set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails


#' ## Global Constants
#' ### Paths to shell tools
#+ shell-tools, eval=FALSE
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
MKDIR=/bin/mkdir                           # PATH to mkdir                           #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #

#' ### Directories
#' Installation directory of this script
#+ script-directories, eval=FALSE
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #

#' ### Files
#' This section stores the name of this script and the
#' hostname in a variable. Both variables are important for logfiles to be able to
#' trace back which output was produced by which script and on which server.
#+ script-files, eval=FALSE
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #
SERVER=`hostname`                          # put hostname of server in variable      #



#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -s <kp_source_db> -t <kp_trg_dir> -o"
  $ECHO "  where -s <kp_source_db>  --  (optional) source kp database ..."
  $ECHO "        -t <kp_trg_dir>    --  (optional) target kp directory ..."
  $ECHO "        -o                 --  (optional) directly open cloned kp database ..."
  $ECHO ""
  exit 1
}

#' ### Start Message
#' The following function produces a start message showing the time
#' when the script started and on which server it was started.
#+ start-msg-fun, eval=FALSE
start_msg () {
  $ECHO "********************************************************************************"
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "Server:  $SERVER"
  $ECHO
}

#' ### End Message
#' This function produces a message denoting the end of the script including
#' the time when the script ended. This is important to check whether a script
#' did run successfully to its end.
#+ end-msg-fun, eval=FALSE
end_msg () {
  $ECHO
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "********************************************************************************"
}

#' ### Log Message
#' Log messages formatted similarly to log4r are produced.
#+ log-msg-fun, eval=FALSE
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`$DATE +"%Y%m%d%H%M%S"`
  $ECHO "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}


#' ## Main Body of Script
#' The main body of the script starts here with a start script message.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
KPDBSOURCE='/Users/pvr/Library/CloudStorage/OneDrive-QualitasGroup/Freigegebene Dokumente/ZWS/Admin_ZWS/kp_zws/20190624_qualitas_zws.kdbx'
KPTRGDIR=${HOME}/Data/kp
OPENKPCLONE='false'
KPAPP=/Applications/KeePassX.app
while getopts ":s:t:oh" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    o)
      OPENKPCLONE='true'
      ;;
    s)
      if test -d $OPTARG; then
        KPDBSOURCE=$OPTARG
      else
        usage "$OPTARG isn't a valid KP source directory"
      fi
      ;;
    t)
      KPTRGDIR=$OPTARG
      ;;
    :)
      usage "-$OPTARG requires an argument"
      ;;
    ?)
      usage "Invalid command line argument (-$OPTARG) found"
      ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.


#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value which corresponds to a valid
#' kp source database
#+ argument-test, eval=FALSE
if [ ! -f "$KPDBSOURCE" ]; then
  usage " *** ERROR: CANNOT FIND kp database: $KPDBSOURCE ..."
fi


#' ## Check KP Target Directory
#' If the kp target directory does not exist, it is created
if [ ! -d "$KPTRGDIR" ]
then
  log_msg $SCRIPT " * Create kp target directory: $KPTRGDIR ..."
  mkdir -p $KPTRGDIR
fi


#' ## Copy KP Source DB
#' Source KP database is copied to target directory. If there is
#' alsready a copy available, rename it
#+ copy-source-kp-db
TDATE=$(date +"%Y%m%d%H%M%S")
KPBNAME=$(basename "$KPDBSOURCE")
KPDBTRGPATH=${KPTRGDIR}/${KPBNAME}
if [ -f "$KPDBTRGPATH" ]
then
  log_msg $SCRIPT " * FOUND $KPDBTRGPATH - saving it away to: ${KPDBTRGPATH}.$TDATE ..."
  mv $KPDBTRGPATH ${KPDBTRGPATH}.$TDATE
fi
log_msg $SCRIPT " * Copy $KPDBSOURCE to $KPTRGDIR ..."
cp "$KPDBSOURCE" $KPTRGDIR


#' ## Open Cloned KP DB
#' If specify directly open cloned kp database
#+ open-clone-kp-db
if [ "$OPENKPCLONE" == 'true' ]
then
 log_msg $SCRIPT " * Open $KPDBTRGPATH ..."
 open -a $KPAPP $KPDBTRGPATH
fi


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

