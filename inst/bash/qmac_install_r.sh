#!/bin/bash
#' ---
#' title: Install R on Mac
#' date:  2021-03-10 07:36:39
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Easy installation of R on a mac
#'
#' ## Description
#' Install R on a Mac where there is no previous version available.
#'
#' ## Details
#' This script downloads to main download page, determines the latest version and then gets the pkg.
#'
#' ## Example
#' ./qmac_install_r.sh
#'
#' ## Set Directives
#' General behavior of the script is driven by the following settings
#+ bash-env-setting, eval=FALSE
set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
#set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
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
  $ECHO "Usage: $SCRIPT -d <download_url> -r <r_version> -u <r_pkg_url> -v <r_version>"
  $ECHO "  where -d <download_url>  --  (optional) specification of download-url ..."
  $ECHO "        -r <r_version>     --  (optional) R version"
  $ECHO "        -u <r_pkg_url>     --  (optional) R pkg download"
  $ECHO "        -v <r_version>     --  (optional) specific version of R to download ..."
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

#' ### Determine R-Version
#' Get R version from download website
#+ get-rversion-fun
get_rversion () {
  # download page with version
  curl $DOWNLOADURL > tmpdlpage.txt
  RVERSION=$(grep 'a href=\"R-[0-9]\.[0-9]\.[0-9]\.pkg' tmpdlpage.txt | head -1 | cut -d'-' -f2)
  RVERSION=${RVERSION:0:5}
  # check whether RVersion could be determined
  if [ "$RVERSION" == '' ]
  then
    log_msg 'get_rversion' " * Cannot determine R version from $DOWNLOADURL"
    log_msg 'get_rversion' " * Inspect content in tmpdlpage.txt ..."
    log_msg 'get_rversion' " * Alteratively specify R version with -r"
    usage ' -r <r_version>'
  else
    rm tmpdlpage.txt
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
DOWNLOADURL='https://cloud.r-project.org/bin/macosx/'
RVERSION=''
RPKGURL=''
while getopts ":d:r:u:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DOWNLOADURL=$OPTARG
      ;;
    r)
      RVERSION=$OPTARG
      ;;
    u)
      RPKGURL=$OPTARG
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


#' ## Check Variables
#' The download URL cannot be empty here
#+ check-vars
if [ "$DOWNLOADURL" == '' ]
then
  usage " -d <download_url> cannot be empty"
fi


#' ## Assemble URL for R.pkg
#' RVERSION is used to specify the download link for R.pkg
#+ r-pkg-dl
if [ "$RPKGURL" == '' ]
then
  # determine R version based on download page
  if [ "$RVERSION" == '' ]
  then
    log_msg $SCRIPT " * Determine R-version ..."
    get_rversion
  fi
  log_msg $SCRIPT " * Found R-version: $RVERSION ..."
  # set up R pkg file
  RPKFILE=R-${RVERSION}.pkg
  RPKGURL=${DOWNLOADURL}${RPKFILE}
  log_msg $SCRIPT " * Download R-pkg from: $RPKGURL ..."
else
  log_msg $SCRIPT " * Specified R package URL for download: $RPKGURL ..."
  RPKFILE=$(basename $RPKGURL)
fi
curl $RPKGURL > $RPKFILE


#' ## Install R.pkg
#' Use open for the installation of R.pkg
#+ ask-for-installation
read -p " * Install downloaded pkg: ${RPKFILE}? [y/n]: " INANSWER
if [ "$INANSWER" == 'y' ]
then
  log_msg $SCRIPT " * Install downloaded pkg: $RPKFILE ..."
  open $RPKFILE
fi


#' ## Ask For Clean Up
#' Ask whether R.pkg should be removed
#+ ask-for-cleanup
read -p " * Installation successful - Remove ${RPKFILE}? [yn]: " CLANSWER
if [ "$CLANSWER" == 'y' ]
then
  log_msg $SCRIPT " * Remove $RPKFILE ..."
  rm $RPKFILE
fi


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

