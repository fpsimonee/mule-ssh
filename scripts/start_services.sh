#!/bin/sh

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

start_ssh() {
  echo "Starting SSHd"
  /usr/sbin/sshd -D
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to start ssh: $status"
    exit $status
  fi
}

start_mule() {
  echo "Starting MULE"
  /opt/mule-standalone/bin/mule -M-Dmule.env=$1 console 
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to start mule: $status"
    exit $status
  fi
}

start_ssh &
start_mule $1 &
