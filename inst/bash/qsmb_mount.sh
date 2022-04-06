#!/bin/bash
#' ---
#' title: SMB Mount
#' date:  2022-02-08 11:43:22
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless mount of a number of shares
#'
#' ## Description
#' Mount a given share to a local mount point using mount_smbfs
#'
#' ## Details
#' If not given any option, a given list of default shares are mounted to local mount points
#'
#' ## Example
#' qsmb_mount.sh -l <local_mount_point> -s <mounted_share>
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
  $ECHO "Usage: $SCRIPT -l <local_mount_point> -s <mounted_share> -u <smb_user> -v <vpn_name>"
  $ECHO "  where -l <local_mount_point>  --   (optional) local mount point ..."
  $ECHO "        -s <mounted_share>      --   (optional) smb share to be mounted ..."
  $ECHO "        -u <smb_user>           --   (optional) alternative smb user ..."
  $ECHO "        -v <vpn_name>           --   (optional) name of vpn network ..."
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

#' ### Wait For VPN Connection
#' Run sleep cycles until VPN is connected
#+ wait-until-vpn-connected
wait_until_vpn_connected () {
  local l_MAX_CYCLES=10
  local l_SLEEP_DURATION=10
  local l_CURRENT_CYCLE=0
  while [ `scutil --nc list | grep "$VPNID" | grep Connected | wc -l` == "0" ] && [ $l_CURRENT_CYCLE -lt $l_MAX_CYCLES ]
  do
    log_msg wait_until_docker_started " ** Current wait cycle: $l_CURRENT_CYCLE ..."
    sleep $l_SLEEP_DURATION
    l_CURRENT_CYCLE=$((l_CURRENT_CYCLE+1))
  done  

}

#' ### Check VPN Connection
#' Check whether vpn connection is active
#+ check-vpn-running-fun
check_vpn_running () {
  log_msg  check_vpn_running " * Check VPN connection with $VPNID ..."
  if [ `scutil --nc list | grep "$VPNID" | grep Connected | wc -l` == "0" ]
  then
    scutil --nc start $VPNID
    wait_until_vpn_connected
  else
    log_msg  check_vpn_running " * Connected to VPN $VPNID ..."
  fi
}

#' ### Setting Default Mount Point
#' Default mount point set based on basename of smbshare
#+ set-def-mnt-fun
set_def_mnt () {
  local l_SMBSHARE=$1
  local l_SMBDIR=$(basename $l_SMBSHARE)
  SMBMNTPNT=/Volumes/$l_SMBDIR
  log_msg set_def_mnt " ** Setting default mount point to: $SMBMNTPNT ..."
}


#' ### Mount Share
#' Give a share and a mount point, run smfs mount of share to mount point.
#+ smb-mount-share-fun
smb_mount_share () {
  local l_SMBSHARE=$1
  local l_MNTPOINT=$2
  local l_SMBLOC="//${SMBUSER}@$l_SMBSHARE"
  log_msg smb_mount_share " ** SMB Share: $l_SMBSHARE ..."
  log_msg smb_mount_share " ** Mount Point: $l_MNTPOINT ..."
  # check whether mount point exists
  if [ ! -d "$l_MNTPOINT" ]
  then
    sudo mkdir -p $l_MNTPOINT
    log_msg smb_mount_share " ** Created dir: $l_MNTPOINT ..."
    sudo chown ${MNTPOINTOWN} $l_MNTPOINT
    log_msg smb_mount_share " ** Setting ownership to: ${MNTPOINTOWN} ..."
  fi

  # run the mount command, if share not already mounted
  if [ $(df -h | grep "$l_SMBSHARE" | wc -l) -eq 0 ]
  then
    log_msg smb_mount_share " ** Mounting $l_SMBLOC to $l_MNTPOINT ..."
    /sbin/mount_smbfs $l_SMBLOC $l_MNTPOINT
  else
    log_msg smb_mount_share " ** Share $l_SMBLOC already mounted to $l_MNTPOINT ..."
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
SMBSHARES=( 'qualstorzws01/data_zws' \
'qualstorzws01/data_tmp' \
'qualstorzws01/data_projekte' \
'qualstorzws01/data_archiv'  \
'qualora01/argus' \
'qualstororatest01/argus_kubota' \
'qualstororatest01/argus_same' \
'qualstororatest01/argus_aebi' \
'qualstororatest01/argus_claas' \
'qualstororatest01/argus_steyr' \
'qualstororatest01/argus_fendt' \
'qualstororatest01/argus_ursus' \
'qualstororatest01/argus_solis')
SMBSHARE=''
SMBMNTPNT=''
SMBUSER=$USER
MNTPOINTOWN="${SMBUSER}:wheel"
VPNID=''   #'Qualitas-VPN (Cisco IPSec) '
while getopts ":l:s:u:v:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    l)
      SMBMNTPNT=$OPTARG
      ;;
    s)
      SMBSHARE=$OPTARG
      ;;
    u)
      SMBUSER=$OPTARG
      ;;
    v)
      VPNID=$OPTARG
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


#' ## Check VPN
#' If a VPN is specified, check whether it is running 
if [ "$VPNID" != '' ]
then
  check_vpn_running
fi
  

#' ## Mounting SMB Shares to Mount Points
#' Depending on options mount single shares or a set of sahres
#+ mount-shares
if [ "$SMBSHARE" == '' ]
then
  log_msg $SCRIPT " * Mounting list of shares ..."
  for SMBSHARE in ${SMBSHARES[@]}
  do
    set_def_mnt $SMBSHARE
    log_msg $SCRIPT " * Mounting $SMBSHARE to $SMBMNTPNT"
    smb_mount_share $SMBSHARE $SMBMNTPNT
    sleep 2
  done
else
  if [ "$SMBMNTPNT" == '' ]
  then
    set_def_mnt $SMBSHARE
  fi
  log_msg $SCRIPT " * Mounting $SMBSHARE to $SMBMNTPNT"
  smb_mount_share $SMBSHARE $SMBMNTPNT
fi


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

