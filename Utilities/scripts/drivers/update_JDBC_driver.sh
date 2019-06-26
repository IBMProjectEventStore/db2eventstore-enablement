#!/bin/bash

# Description of Workflow:
# 1/ get filemgmt pod name, container id,image name
# 2/ get NODE_IP where filemgmt pod is located.
# 3/ copy db2jcc4.jar from eventstore dir under /user-home
#    to filemgmt pod's /dbdrivers local directory
# 4/ go to the filemgmt's resident node. Docker commit filemgmt
#    container as image, and push it to the docker registry. 
# 5/ delete filemgmt pod, and wait till new pod come up.

NAME_SPACE="zen"

function usage ()
{
cat <<-USAGE #| fmt

Usage: $0 [OPTIONS] [arg]
---
This script updates the JDBC driver "db2jcc4.jar" in the IBM Cloud 
Private for Data (ICP4D) deployments's filemgmt pod. The updated 
driver will have the compatible version with other ICP4D services.

OPTIONS:
=======
--name_space|-n       [Optional] Kubernetes name space that the ICP4D is deployed to. If not provided, the default value of "zen" will be used.


Note: This script must be executed as the [ root ] user.
USAGE
}

# ensure it's run by root user.
if [ "$EUID" -ne 0 ]
    then echo " Run as root"
    exit
fi

while [ -n "$1" ]
do
   case $1 in
      -h|--help)
        usage >&2
        exit 0
        ;;
      --name_space|-n)
        NAME_SPACE=$2
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        usage >&2
        exit 1
        ;;
   esac
done

# get filemgmt pod name, container id,image name

FILEMGMT_POD=`kubectl get po -n "${NAME_SPACE}" | grep filemgmt | awk {'print $1'}`

FILEMGMT_CONTAINER=`kubectl describe po -n "${NAME_SPACE}" "${FILEMGMT_POD}" | grep "Container ID:" | awk {'print $3'} | awk -F 'docker://' '{print $2}'`

FILEMGMT_IMAGE=`kubectl describe po -n "${NAME_SPACE}" "${FILEMGMT_POD}" | grep "Image:" | awk {'print $2'}`

# get NODE_IP where filemgmt pod is located.

NODE_IP=`kubectl describe po -n "${NAME_SPACE}" "${FILEMGMT_POD}" | grep "Node:" | awk {'print $2'} |awk -F '/' '{print $1}'`

# copy new db2jcc4.jar into the pod's /dbdrivers dir from user-home pvc
echo "[Status] Updating JDBC driver..."
kubectl exec -n "${NAME_SPACE}" -it "${FILEMGMT_POD}" -- bash -c "cp /user-home/_global_/eventstore/db2jcc4.jar /dbdrivers/db2jcc4.jar"

# commit container to image, and push to registry
echo "[Status] Updating filemgmt docker image in the registry..."
ssh -o StrictHostKeyChecking=no root@"${NODE_IP}" "docker commit ${FILEMGMT_CONTAINER} ${FILEMGMT_IMAGE}"
ssh -o StrictHostKeyChecking=no root@"${NODE_IP}" "docker push ${FILEMGMT_IMAGE}"

# delete old pod, and wait till new pod is running.
echo "[Status] Waiting until new driver to take effect..."
kubectl delete po "${FILEMGMT_POD}" -n "${NAME_SPACE}"
sleep 10
while [[ $(kubectl get po -n "${NAME_SPACE}" | grep filemgmt | grep -c -E "1/1.*Running") -ne 1 ]]
do
   echo "Waiting for filemgmt pod to re-start..." && sleep 20
done

echo "[Status] JDBC driver update is successful !"
