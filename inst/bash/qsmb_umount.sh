#!/bin/bash
#' ---
#' title: Qualitas SMB Un-mount
#' date:  2022-02-08 16:49:50
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless un-mounting of a list of smb shares
#'
#' ## Description
#' SMB Shares are unmounted
#'
#' ## Details
#' This takes a list of attached shares and un-mounts them. This script does the opposite of qsmb_mount.sh.
#'
#' ## Example
#' ./qsmb_umount.sh
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
  $ECHO "Usage: $SCRIPT  -l <local_mount_point> "
  $ECHO "  where -l <local_mount_point>  --   (optional) local mount point ..."
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

#' ### Check Un-Mouting
#' If a mountpoint dir exist, then un-mount it
#+ smb-umount-fun
smb_umount () {
  local l_MOUNTSHARE=$1
  if [ -d "$l_MOUNTSHARE" ]
  then
    log_msg smb_umount " ** Umounting $l_MOUNTSHARE ..."
    umount $l_MOUNTSHARE
  fi
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
SMBMNTPNTS=( '/Volumes/data_zws' \
'/Volumes/data_tmp' \
'/Volumes/data_projekte' \
'/Volumes/data_archiv' \
'/Volumes/argus_kubota' \
'/Volumes/argus_same' \
'/Volumes/argus_aebi' \
'/Volumes/argus_claas' \
'/Volumes/argus_steyr' \
'/Volumes/argus_fendt' \
'/Volumes/argus_ursus' \
'/Volumes/argus_solis' \
'/Volumes/argus' )
SMBMNTPNT=''
while getopts ":l:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    l)
      SMBMNTPNT=$OPTARG
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



#' ## Un-Mount Mounted Shares
#' Either for a complete list or for a single mounted share, run the umount command
#+ smb-umount
if [ "$SMBMNTPNT" == '' ]
then
  for SMBMNTPNT in ${SMBMNTPNTS[@]}
  do
    log_msg $SCRIPT "Try un-mounting $SMBMNTPNT ..."
    smb_umount $SMBMNTPNT
    sleep 2
  done
else
  log_msg $SCRIPT "Try un-mounting $SMBMNTPNT ..."
  smb_umount $SMBMNTPNT
fi


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

