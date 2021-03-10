#!/bin/bash
#' ---
#' title: Install LibreOffice
#' date:  2021-03-10 15:00:57
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless installation of LibreOffice
#'
#' ## Description
#' Download and Installation of LibreOffice on a Mac
#'
#' ## Details
#' Commandline tools like curl are used for the download and open is used to install the dmg file.
#'
#' ## Example
#' ./qmac_installlibo.sh
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
  $ECHO "Usage: $SCRIPT  -d <download_url> -v <r_version>"
  $ECHO "  where -d <download_url>     --  (optional) specification of download-url ..."
  $ECHO "        -v <rstudio_version>  --  (optional) specific version of RStudio to download ..."
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

get_libo_version () {
  curl $DOWNLOADURLVERSION > tmpdllo.txt
  LIBOVERSION=$(grep version= tmpdllo.txt | grep macOS | head -1 | cut -d '=' -f4 | cut -d '&' -f1)
  # check whether LibO-Version could be determined
  if [ "$LIBOVERSION" == '' ]
  then
    log_msg 'get_libo_version' " * Cannot determine LibO version from $DOWNLOADURLVERSION"
    log_msg 'get_libo_version' " * Inspect content in tmpdllo.txt ..."
    log_msg 'get_libo_version' " * Alteratively specify LibO version with -r"
    usage ' -r <r_version>'
  else
    rm tmpdllo.txt
  fi
}

#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
DOWNLOADURLVERSION='https://www.libreoffice.org/download/download/'
DOWNLOADURLDMGSTEM='https://download.documentfoundation.org/libreoffice/stable/'
DOWNLOADURLDMG=''
LIBOVERSION=''
while getopts ":d:v:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DOWNLOADURLDMG=$OPTARG
      ;;
    v)
      LIBOVERSION=$OPTARG
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



#' ## Get the LibO-version
#' If the LibO-version is not specified, then get it from the web
#+ get-libo-version
if [ "$LIBOVERSION" == '' ]
then
  log_msg $SCRIPT " * Determine LibO-version ..."
  get_libo_version
fi

log_msg $SCRIPT " * Found LibO version: $LIBOVERSION ..."


#' ## Assemble URL for LibO.dmg
#' LIBOVERSION is used to specify the download link for LibO.dmg
#+ libo-pkg-dl
LIBODMGFILE="LibreOffice_${LIBOVERSION}_MacOS_x86-64.dmg"
if [ "$DOWNLOADURLDMG" = '' ]
then
  LIBOURL="${DOWNLOADURLDMGSTEM}${LIBOVERSION}/mac/x86_64/${LIBODMGFILE}"
else
  LIBOURL=$DOWNLOADURLDMG
fi
log_msg $SCRIPT " * Download LibO.dmg from: $LIBOURL ..."
curl $LIBOURL > $LIBODMGFILE


#' ## Install LibO.dmg
#' Use open for the installation of LibO.dmg
read -p " * Install downloaded dmg: ${LIBODMGFILE}? [y/n]: " INANSWER
if [ "$INANSWER" == 'y' ]
then
  log_msg $SCRIPT " * Install downloaded dmg: $LIBODMGFILE ..."
  open $LIBODMGFILE
fi

#' ## Ask For Clean Up
#' Ask whether RStudio.dmg should be removed
read -p " * Installation successful - Remove ${LIBODMGFILE}? [y/n]: " CLANSWER
if [ "$CLANSWER" == 'y' ]
then
  log_msg $SCRIPT " * Remove $LIBODMGFILE ..."
  rm $LIBODMGFILE
fi



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

