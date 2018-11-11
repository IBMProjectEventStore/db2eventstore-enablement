#!/bin/bash
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. ${DIR}/storage_helper.sh

# Get the Storage and the Compute paths
k8sdir=`dirname ${0}`
. ${k8sdir}/k8shelper_local.sh

CONFIG_PATH=${k8sdir}/scripts/

K8SNAMESPACE=$(cd ${CONFIG_PATH} ; ./configuration provisioning.kubernetes_namespace )

USER=admin
PASSWORD=Lightbend_2018_IBM
DATABASE=KillrWeather
CONFIGURATION=172.31.45.19:1101,172.31.46.167:1101,172.31.32.92:1101

function usage()
{

cat <<-USAGE #| fmt
	Usage: $0 [OPTIONS] [arg]
	OPTIONS:
	=======
	--offset          Mandatory integer. First run: 1, second run: 31, third run: (previous run + 30)
	--timeout         Mandatory integer in minutes. How long do you want to run it for?
USAGE
}

while [ -n "$1" ]
do
   case $1 in
      --offset)
         OFFSET=$2
         shift 2
         ;;
			--timeout)
         TIMEOUT=$2
         shift 2
         ;;
      --help|-h)
	usage >&2
        exit 0
        ;;
      --*)
        echo "Unknown option: $1"
        usage >&2
        exit 1
        ;;
      *)
        usage >&2
        exit 1
        ;;
   esac
done

if [ -z "$OFFSET" ]; then
    echo "Error: You need an offset. First run: 1, second run: 13, third run: (previous run offset + 12)"
    exit 1
fi

if [ -z "$TIMEOUT" ]; then
    echo "Error: You need an timeout in minutes"
    exit 1
fi

TIMEOUT=$((TIMEOUT*60))

FAST_DATA_FEED_COMMAND="/usr/bin/scala -cp /bluspark/ibm-event_2.11-assembly-1.0.jar com.ibm.event.example.lightBendIngestDriver -c ${CONFIGURATION} --dbname ${DATABASE} --maxruntime ${TIMEOUT} --username ${USER} --password ${PASSWORD}"

for i in `seq 0 2`
do
  PERF_CONTAINER=`kubectl get pod -n ${K8SNAMESPACE} --selector=job-name=bluspark-tenant-perf-${i} --no-headers=true -o custom-columns=:metadata.name`
  echo "Found the following perf pod running: ${PERF_CONTAINER}"
  echo "About to start the fast data feed"
  for j in `seq 1 10`
  do
		echo "About to execute ${FAST_DATA_FEED_COMMAND} --intoffset $((j+OFFSET))"
    ( kubectl exec ${PERF_CONTAINER} -n ${K8SNAMESPACE} xrun "${FAST_DATA_FEED_COMMAND} --intoffset $j" ) &
  done
  OFFSET=$((OFFSET+j))
done
