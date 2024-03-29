#!/bin/bash
#' ---
#' title: Create RStudio Project
#' date:  2021-10-19 18:12:17
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless creation of a new rstudio project
#'
#' ## Description
#' Start a new RStudio project in the local working folder
#'
#' ## Details
#' This copies a template RStudio project to the local folder and starts a new instance of RStudio
#'
#' ## Example
#' nrsproj -p new_rstudio_project
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
  $ECHO "Usage: $SCRIPT -p <rstudio_project> -t <rstudio_template> -h"
  $ECHO "  where -p <rstudio_project>   --  specifies the name of the rstudio project to be created ..."
  $ECHO "        -t <rstudio_template>  --  path to the rstudio template file"
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
RSTPROJTMPLPATH='/opt/qmactools/template/rstudio/RStudioTemplate.Rproj'
RSTPROJNAME=$(date +"%Y%m%d%H%M%S")_rsproj
while getopts ":p:t:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    p)
      RSTPROJNAME=$OPTARG
      ;;
    t)
      RSTPROJTMPLPATH=$OPTARG
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
if test "$RSTPROJNAME" == ""; then
  usage "-p <rstudio_project> not defined"
fi
if test "$RSTPROJTMPLPATH" == ""; then
  usage "-t <rstudio_template> not defined"
fi


#' ## Check RStudio Project Name
RSTPROJFILE=$(basename $RSTPROJNAME)'.Rproj'
RSTPROJDIR=$(dirname $RSTPROJNAME)
log_msg $SCRIPT " * RSTPROJFILE: $RSTPROJFILE ..."
mkdir -p $RSTPROJNAME
log_msg $SCRIPT " * Created dir: $RSTPROJNAME ..."

#' ## RStudio Project Creation
#' Copy the template and rename it to the given project name
#+ copy-rename-tmpl
RSTPROJTMPLFILE=$(basename $RSTPROJTMPLPATH)
log_msg $SCRIPT " * Copy template from: $RSTPROJTMPLPATH to: $RSTPROJNAME ..."
cp $RSTPROJTMPLPATH $RSTPROJNAME


log_msg $SCRIPT " * Rename $RSTPROJNAME/$RSTPROJTMPLFILE to $RSTPROJNAME/$RSTPROJFILE  ..."
mv $RSTPROJNAME/$RSTPROJTMPLFILE $RSTPROJNAME/$RSTPROJFILE


#' ## Start RStudio
#' Use new project and start RStudio
#+ start-rstudio
open -a /Applications/RStudio.app $RSTPROJNAME/$RSTPROJFILE


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

