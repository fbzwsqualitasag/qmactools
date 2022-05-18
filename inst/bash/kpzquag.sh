#!/bin/bash
#' ---
#' title: Manage KeePass Files
#' date:  2022-05-18 13:47:42
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless updating of KeePass files
#'
#' ## Description
#' Manage KeePass file for FB-ZWS Qualitas AG
#'
#' ## Details
#' Management involves cloning, updating and showing of KeePass file.
#'
#' ## Example
#' ./kpzquag
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
  $ECHO "Usage: $SCRIPT -c -s <source_kp_file> -t <target_dir> -u"
  $ECHO "  where -c                   --  (optional) cloning source kp file to target directory ..."
  $ECHO "        -s <source_kp_file>  --  (optional) path to source kp file ..."
  $ECHO "        -t <target_dir>      --  (optional) target directory for kp file ..."
  $ECHO "        -u                   --  (optional) update source kp file ..."
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

#' ### Update KP File
#' The source kp-file is updated
#+ update-kp-file-fun
update_kp_file () {
  $KPPATH "$SOURCEKPPATH"
  CLONEKPFILE='true'
}

#' ### Clone KP File
#' A source kp-file is cloned to a local target directory
#+ clone-kp-file-fun
clone_kp_file () {

  if [ ! -d "$TARGETKPDIR" ]
  then
    log_msg clone_kp_file " * Create kp target directory ..."
    mkdir -p "$TARGETKPDIR"
  fi

  if [ -f "$TARGETKPPATH" ]
  then
    log_msg clone_kp_file " * Save away target_kp_path: $TARGETKPPATH to $TARGETKPPATH.$TDATE ..."
    mv $TARGETKPPATH $TARGETKPPATH.$TDATE
  fi

  log_msg clone_kp_file " * Copy $SOURCEKPPATH to $TARGETKPDIR ..."
  cp "$SOURCEKPPATH" $TARGETKPDIR
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
CLONEKPFILE='false'
SOURCEKPPATH='/Users/pvr/Library/CloudStorage/OneDrive-QualitasGroup/Freigegebene Dokumente/ZWS/Admin_ZWS/kp_zws/20190624_qualitas_zws.kdbx'
TARGETKPDIR='/Users/pvr/Data/kp/kpzquag'
UPDATEKPFILE='false'
KPAPP=/Applications/KeePassX.app
KPPATH=/Applications/KeePassX.app/Contents/MacOS/KeePassX
while getopts ":cs:t:uh" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    c)
      CLONEKPFILE='true'
      ;;
    s)
      if test -f $OPTARG; then
        SOURCEKPPATH=$OPTARG
      else
        usage "$OPTARG is not a valid source kp file"
      fi
      ;;
    t)
      TARGETKPDIR=$OPTARG
      ;;
    u)
      UPDATEKPFILE='true'
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
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE
if test "$SOURCEKPPATH" == ""; then
  usage "-s <source_kp_path> not defined"
fi
if test "$TARGETKPDIR" == ""; then
  usage "-t <target_kp_dir> not defined"
fi


#' ## Setting of Constants
#' Global constants are set
#+ set-global-const
TDATE=$(date +"%Y%m%d%H%M%S")
KPFILE=$(basename "$SOURCEKPPATH")
TARGETKPPATH=$TARGETKPDIR/$KPFILE
log_msg $SCRIPT " * TARGETKPPATH: $TARGETKPPATH ..."


#' ## Update KP-File
#' Update of source KP file
#+ update-kp-file
if [ "$UPDATEKPFILE" == 'true' ]
then
  log_msg $SCRIPT " * Updating KP-file at: $SOURCEKPPATH ..."
  update_kp_file
fi


#' ## Clone KP File
#' The remote kp-file is cloned to a local target directory
#+ clone-kp-file
if [ "$CLONEKPFILE" == 'true' ]
then
  log_msg $SCRIPT " * Cloning KP-file from $SOURCEKPPATH to $TARGETKPDIR ..."
  clone_kp_file
fi


#' ## Open Local KP-file
#' After updating and cloning the new local kp-file
#' is opened
#+ open-local-kp-file
log_msg $SCRIPT " * Open $TARGETKPPATH ..."
open -a $KPAPP $TARGETKPPATH


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

