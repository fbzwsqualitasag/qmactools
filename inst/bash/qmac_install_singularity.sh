#!/bin/bash
#' ---
#' title: Install Singularity Viewer
#' date:  2021-03-23 14:04:46
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Automated installation of singularity viewer on MacOS
#'
#' ## Description
#' Download and installation of the latest version of the singularity viewer for MacOS
#'
#' ## Details
#' The latest version of singularity is determined from the website or given as a commandline argument
#'
#' ## Example
#' ./qmac_install_singulairty.sh
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
  $ECHO "Usage: $SCRIPT -d <download_url>"
  $ECHO "  where -d <download_url>         --  url from where singularity can be downloaded ..."
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

#' ### Singularity Version
#' Function to determine latest version of singularity viewer
#+ get-si-version-fun
get_si_dlurl () {
  curl $DOWNLOADURLVERSION > tmpsidl.txt
  DOWNLOADURLDMG=$(grep 'Download Now' tmpsidl.txt | head -1 | cut -d '=' -f2 | cut -d ' ' -f1 | sed -e "s/\"//g")
  # check
  if [ "$DOWNLOADURLDMG" == '' ]
  then
    log_msg 'get_si_dlurl' " * Cannot determine the download url for singularity from: $DOWNLOADURLVERSION"
    log_msg 'get_si_dlurl' ' * Inspect tmpsidl.txt'
    log_msg 'get_si_dlurl' ' * Alternatively specify download url with -d commandline argument'
    usage ' -d <download_url> '
  else
    rm tmpsidl.txt
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
DOWNLOADURLVERSION='https://sylabs.io/singularity-desktop-macos/'
DOWNLOADURLDMG=''
while getopts ":d:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DOWNLOADURLDMG=$OPTARG
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


#' ## Singularity Version
#' The version of the latest singularity viewer is either taken from
#' the commandline with -v or it is determined from the website
#+ singularity-version
if [ "$DOWNLOADURLDMG" == '' ]
then
  log_msg $SCRIPT " * Determine Singularity Download URL ..."
  get_si_dlurl
fi


#' ## Download
#' Download the singulrity.dmg file from  $DOWNLOADURLDMG
#+ dl-msg
SIDMGFILE=$(basename $DOWNLOADURLDMG)
log_msg "$SCRIPT" " * Download singularity viewer from: $DOWNLOADURLDMG ..."
curl $DOWNLOADURLDMG > $SIDMGFILE


#' ## Installation
#' Ask the user whether the downloaded dmg should be installed
#+ install-dmg
read -p " * Install downloaded dmg (${SIDMGFILE})? [y/n]: " INANSWER
if [ "$INANSWER" == 'y' ]
then
  log_msg $SCRIPT " * Install downloaded dmg: $SIDMGFILE ..."
  open $SIDMGFILE
fi


#' ## Ask For Clean Up
#' Ask whether singularity.dmg should be removed
read -p " * Installation successful - Remove ${SIDMGFILE}? [y/n]: " CLANSWER
if [ "$CLANSWER" == 'y' ]
then
  log_msg $SCRIPT " * Remove $SIDMGFILE ..."
  rm $SIDMGFILE
fi


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

