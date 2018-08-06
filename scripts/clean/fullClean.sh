#!/bin/bash
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. ${DIR}/storage_helper.sh

# Get the Storage and the Compute paths
export deletePath=/ibm/eventstore
REMOTE_USER=root

k8sdir=`dirname ${0}`
. ${k8sdir}/k8shelper_local.sh

CONFIG_PATH=${k8sdir}/scripts/

export K8SNAMESPACE=$(cd ${CONFIG_PATH} ; ./configuration provisioning.kubernetes_namespace )

wait_timeout=300
clean=0
errno=0
REMOTE_USER=root

function run_remotely {
   local REMOTE_HOST=$1
   local REMOTE_USER=$2
   local REMOTE_USER_PASSWORD=$3
   shift 3

   if [ ${REMOTE_USER} == "root" ]
   then
      ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} $@
   fi
}

function cleanup_shared {
   RET=0
   MOUNT_POINT=/mnt/eventstore_gluterfs_for_cleanup
   mount_glusterfs ${EVENTSTORE_GLUSTER_VOLUME} ${MOUNT_POINT}
   RES=$?
   if [ $RES -ne 0 ]
   then
      exit $RES
   fi

   for i in `ls -d ${MOUNT_POINT}/* | grep -e '.TO_CLEANUP'` ; do
     echo "***** About to delete ** $i ** in the Shared Storage area *****"
     rm -rf $i
     RES=$?
     if [ $RES -ne 0 ]
     then
        echo "Error: unable to remove $i: $RES"
        RET=1
     else
        echo "Removed $i"
     fi
   done
   RES=$?
   if [ $RES -ne 0 ]
   then
     echo "Error: unable to complete delete of files from ${MOUNT_POINT}: $RES"
     RET=1
   fi

   umount_glusterfs ${MOUNT_POINT}
   RES=$?
   if [ $RES -ne 0 ]
   then
      RET=3
   fi
   exit $RET
}

echo "Local path: $path"

nodes=`kubectl get nodes | awk '{print $1}' | grep -i -v NAME`
RES=$?
if [ $RES -ne 0 ]
then
   echo "Error: unable to query kube to get nodes: $RES"
   exit 1
fi

#cleanup your bluspark installation
for node in $nodes; do
    if [ "x$node" != "x`hostname`" ]; then
        echo "***** About to delete ${deletePath}/* in the Local Storage area on node ${node}"
        ( ssh -o StrictHostKeyChecking=no root@${node} 'for i in `ls -d /ibm/eventstore/* | grep -e .TO_CLEANUP`; do rm -rf $i; done' ) &
        PIDS+=" $!"
    else
        echo "***** About to delete ${deletePath}/* in the Local Storage area on localhost"
        ( for i in `ls -d ${deletePath}/* | grep -e '.TO_CLEANUP'`; do rm -rf $i; done ) &
        PIDS+=" $!"
    fi
done

( cleanup_shared ) &
PID_STORAGE=$!

RES=0
for p in $PIDS;
do
   wait $p
   PID_RES=$?
   if [ $PID_RES -ne 0 ]
   then
       echo "Error: background process $p failed with error code $PID_RES"
       RES=$PID_RES
   fi
done
wait $PID_STORAGE
PID_RES=$?
if [ $PID_RES -ne 0 ]
then
   echo "Error: background process $p for storage failed with error code $PID_RES"
   RES=$PID_RES
fi
if [ $RES -ne 0 ]
then
   echo "Error: one of the background processes terminated abnormally"
   exit $RES
fi

echo "cleanup completed."
