#!/bin/bash -ex

k8sdir=`dirname ${0}`
. ${k8sdir}/k8shelper_local.sh

CONFIG_PATH=${k8sdir}/scripts/

export K8SNAMESPACE=$(cd ${CONFIG_PATH} ; ./configuration provisioning.kubernetes_namespace )

wait_timeout=300
clean=0
errno=0
REMOTE_USER=root

##
#delete the resource definitions
$k8sdir/delete.sh
RES=$?
if [ $RES -ne 0 ]; then
   echo "Warning with return code $RES: resouces might not be cleaned up completely"
fi

# Move the data aside
$k8sdir/clean.sh --quick_move --user "${REMOTE_USER}" --password ""
RES=$?
if [ $RES -ne 0 ]; then
  echo "Warning with return code $RES: data and metadata might not be cleaned up completedly"
fi

# Wait 30s to catch potential Terminating pods
sleep 30

## Remove any non-terminating pods - as we have seen some stay around
kubectl get pods --all-namespaces | grep Terminating | awk '{print "kubectl delete pod --grace-period=0 --force -n ", $1, $2, "&"}' > deleteKubectlPod.sh
chmod +x deleteKubectlPod.sh
$k8sdir/deleteKubectlPod.sh

## Refresh with clean up step
$k8sdir/refresh.sh --virtual_ip 172.31.46.167

## Print all the pods
kubectl get po --all-namespaces
