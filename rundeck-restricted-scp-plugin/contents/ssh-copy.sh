#!/bin/bash

#####
# ssh-copy.sh
# This script executes the system "scp" command to copy a file
# to a remote node.
# usage: ssh-copy.sh [username] [hostname] [file]
#
# It uses some environment variables set by RunDeck if they exist.  
#
# RD_NODE_SCP_DIR: the "scp-dir" attribute indicating the target
#   directory to copy the file to.
# RD_NODE_SSH_PORT:  the "ssh-port" attribute value for the node to specify
#   the target port, if it exists
# RD_NODE_SSH_KEYFILE: the "ssh-keyfile" attribute set for the node to
#   specify the identity keyfile, if it exists
# RD_NODE_SSH_OPTS: the "ssh-opts" attribute, to specify custom options
#   to pass directly to ssh.  Eg. "-o ConnectTimeout=30"
# RD_NODE_SCP_OPTS: the "scp-opts" attribute, to specify custom options
#   to pass directly to scp.  Eg. "-o ConnectTimeout=30". overrides ssh-opts.
# RD_NODE_SSH_TEST: if "ssh-test" attribute is set to "true" then do
#   a dry run of the ssh command
#####

USER=$1
shift
HOST=$1
shift
FILE=$1

absolute_path=$(readlink -n -s -f $FILE)
if [ -z "$absolute_path" ]; then
  echo "$FILE is no permission" >&2
  exit 1
fi

MATCH_FLAG=0
ACCEPT_FILE_PATH=("${RD_RUNDECK_BASE}/var/tmp/" "${RD_RUNDECK_BASE}/var/cache/ScriptURLNodeStepExecutor/")
for (( i=0; i < ${#ACCEPT_FILE_PATH[@]}; ++i ))
do
  if [[ "$absolute_path" =~ ^${ACCEPT_FILE_PATH[$i]}.* ]]; then
    MATCH_FLAG=1
    break
  fi
done

if [ $MATCH_FLAG -eq 0 ]; then
  echo "$FILE is no permission" >&2
  exit 1
fi

DIR=${RD_NODE_SCP_DIR:-/tmp}

# use RD env variable from node attributes for ssh-port value, default to 22:
PORT=${RD_NODE_SSH_PORT:-22}

# extract any :port from hostname
XHOST=$(expr "$HOST" : '\(.*\):')
if [ ! -z $XHOST ] ; then
  PORT=${HOST#"$XHOST:"}
  HOST=$XHOST
fi

SSHOPTS="-p -P $PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet"

# use ssh-keyfile node attribute from env vars
if [ -n "${RD_NODE_SSH_KEYFILE:-}" ]
then
  SSHOPTS="$SSHOPTS -i $RD_NODE_SSH_KEYFILE"
elif [ -n "${RD_CONFIG_SSH_KEY_STORAGE_PATH:-}" ]
then
  mkdir -p "/tmp/mtl-exec"
  SSH_KEY_STORAGE_PATH=$(mktemp "/tmp/mtl-exec/ssh-keyfile.$USER@$HOST.XXXXX")
  echo "$RD_CONFIG_SSH_KEY_STORAGE_PATH" > $SSH_KEY_STORAGE_PATH
  SSHOPTS="$SSHOPTS -i $SSH_KEY_STORAGE_PATH"
fi

# use any node-specified ssh options
if [ ! -z "$RD_NODE_SCP_OPTS" ] ; then
  SSHOPTS="$SSHOPTS $RD_NODE_SCP_OPTS"
elif [ ! -z "$RD_NODE_SSH_OPTS" ] ; then
  SSHOPTS="$SSHOPTS $RD_NODE_SSH_OPTS"
fi

RUNSCP="scp $SSHOPTS $FILE $USER@$HOST:$DIR"

# if ssh-test is set to "true", do a dry run
if [ "true" = "$RD_NODE_SSH_TEST" ] ; then
  echo "[mtl-exec]" $RUNSCP 1>&2
  echo $DIR/$(basename $FILE) # echo remote filepath
  exit 0
fi

# finally, execute scp but don't print to STDOUT
$RUNSCP 1>&2 || exit $? # exit if not successful
echo $DIR/$(basename $FILE) # echo remote filepath

[[ -n "${SSH_KEY_STORAGE_PATH:-}" ]] && rm -f "${SSH_KEY_STORAGE_PATH}"

# Done.
