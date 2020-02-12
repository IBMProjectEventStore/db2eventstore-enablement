#!/bin/bash -x

function usage() {
cat <<-USAGE #| fmt

Prerequisites:
=======
1/ User need to ensure that they are executing the script on a host that has
   openshift client (oc) installed and that they are under the desired openshift 
   project that their database will be deployed under. 
   This can be validated by running `oc project` command.
3/ User need to have 'db2eventstore' installed as an CP4D add-on.
4/ User should NOT have created the db2eventstore database instance.

Description:
=======
This script is used to change the Object Storage type of the db2eventstore
database instance to be created on CP4D. The user need to execute the script after
they have the 'db2eventstore' installed as an CP4D add-on but before they have
created a db2eventstore database instance. Users have to provide this script with the
target namespace (oc project name) and the desired Object Storage type. When finished,
the new db2eventstore database instances created in the target namespace will be
created using the desired Cloud Object Storage type if user choose to create the
database with Cloud Object Storage.

Usage: $0 [OPTIONS]

OPTIONS:
=======
--namespace | -n   Namespace under which the db2eventstore database will be created.
--object-storage-type | -t    Type of object storage that db2eventstore will be installed with.
                              It can be one of <"MINIO" / "COS" / "S3">
                              - MINIO: Open source version of MINIO
                              - S3: AWS S3
                              - COS: IBM Cloud Object Storage

Example:
=======
./cp4d_change_objectStorage_type.sh --namespace zen --object-storage-type "S3"
USAGE
}

NAMESPACE=""
COS_TYPE=""

while [ -n "$1" ]
do
   case $1 in
      --namespace|-n)
         NAMESPACE=$2
         shift 2
         ;;
      --object-storage-type|-t)
         COS_TYPE=$2
         shift 2
         ;;
      --help|-h)
         usage >&2
         exit 0
         ;;
      *)
         echo "Unknown option: $1"
         usage >&2
         exit 1
         ;;
   esac
done

function _log()       { echo -e "[`date`]$1"; }
function log_info()   { _log "[INFO] \e[34m$1\e[39m"; }
function log_passed() { _log "[PASSED] \e[32m$1\e[39m"; }
function log_warn()   { _log "[WARN] \e[33m$1\e[39m"; }
function log_error()  { _log "[ERROR] \e[31m$1\e[39m" >&2; }

function check_errors() {
   local RES=$1
   # current command
   local COMMAND=$2
   # optional msg to print at error
   local MSG=$3

   if [ $RES -ne 0 ]; then
      log_error "Error Code '$RES' : $COMMAND"
      [[ ! -z "$MSG" ]] && log_error "$MSG"
      rm -rf ${TEMP_DIR}
      exit ${RES}
   else
      # print the current command if succeeded
      log_info "$COMMAND"
   fi
}

function check_es_addon_install() {
   oc get po -n "${NAMESPACE}" | grep -q "db2eventstore-catalog"
   local ES_CATALOG_EXISTS="$?"
   oc exec -it ${ZEN_DB_CORE_POD} -- ls -l "/user-home/_global_/databases/" | grep -q "db2eventstore.tgz"
   local ES_TAR_EXISTS="$?"
   if [[ "${ES_CATALOG_EXISTS}" -eq "0" ]] && [[ "${ES_TAR_EXISTS}" -eq "0" ]]; then
      return "0"
   else
      return "1"
   fi
}

function containsElement () {
   local e match="$1"
   shift
   for e; do [[ "$e" == "$match" ]] && return 0; done
   return 1
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TIMESTAMP=`date "+%Y-%m-%d-%H.%M.%S"`
TEMP_DIR="${SCRIPT_DIR}/tmp_cos_type_${TIMESTAMP}"
mkdir -p "${TEMP_DIR}"


if [ -z "${COS_TYPE}" ]; then
   log_error "Type of Object Storage must be provided with --object-storage-type flag."
   usage >&2
   exit 1
fi

# check if COS_TYPE is among 3 allowd values
type_array=("MINIO" "S3" "COS")
if ! containsElement "${COS_TYPE}" "${type_array[@]}" ; then
   log_error "--object-storage-type provided: '${COS_TYPE}' is invalid. It can only be one of <'COS' | 'S3' |'MINIO'>."
   usage >&2
   exit 1
fi

if [ -z "${NAMESPACE}" ]; then
   log_error "User need to provide the namespace under which the db2eventstore database will be created with --namespace flag"
   usage >&2
   exit 1
fi

if ! oc get project | grep -q "\b${NAMESPACE}\b"; then
   log_error "User provided namespace: '${NAMESPACE}' doesn't exist."
   usage >&2
   exit 1
fi

if check_es_addon_install ; then
   log_error "CP4D add-on: 'db2eventstore' is not found, please ensure you have 'db2eventstore' installed as a CP4D add-on."
   usage >&2
   exit 1
fi

oc project ${NAMESPACE}
check_errors $? "Switching to target namespace."

ZEN_DB_CORE_POD=$(oc get po -n ${NAMESPACE} | grep "zen-database-core" | awk '{print $1}')

oc cp "${NAMESPACE}/${ZEN_DB_CORE_POD}":/user-home/_global_/databases/db2eventstore.tgz "${TEMP_DIR}/db2eventstore.tgz"
check_errors $? "Copying original db2eventstore helm chart."

tar -xvf "${TEMP_DIR}/db2eventstore.tgz" -C ${TEMP_DIR}
check_errors $? "Untar the db2eventstore helm chart."
sed -ie "/objectStorage:/,/type:/{s/type:.*/type: \"${COS_TYPE}\"/"} "${TEMP_DIR}/ibm-db2-eventstore-prod/values.yaml"
check_errors $? "Updating Object Storage type."

cd "${TEMP_DIR}"
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
check_errors $? "Preparing helm binary"
tar -zxvf helm-v2.11.0-linux-amd64.tar.gz
cp linux-amd64/helm "${TEMP_DIR}/"
cd "${TEMP_DIR}"
${TEMP_DIR}/helm package "${TEMP_DIR}/ibm-db2-eventstore-prod" -d "${TEMP_DIR}"
check_errors $? "Packaging helm chart."
\mv ${TEMP_DIR}/ibm-db2-eventstore-prod*.tgz ${TEMP_DIR}/db2eventstore.tgz
check_errors $? "Finishing up preparing db2eventstore chart."
oc cp "${TEMP_DIR}/db2eventstore.tgz" ${NAMESPACE}/${ZEN_DB_CORE_POD}:/user-home/_global_/databases/db2eventstore.tgz
check_errors $? "Uploading modified helm chart."

rm -rf ${TEMP_DIR}
check_errors $? "Removing temporary files."
log_passed "Script finished clean."
