#!/bin/bash

function usage() {
cat <<-USAGE #| fmt

Prerequisites:
=======
1/ The script should be executed on a host that has openshift client (oc) installed.
2/ User need to ensure they are under the desired openshift project that their 
   database will be deployed under. This can be validated by running `oc project` command.

Description:
=======
The script is used to add user's SSL certificate of Cloud Object Storage to a
IBM Db2 Event Store deployment. The user need to provide the target deployment ID
and the path of a SSL certificate of Cloud Object Storage as argument. When finished,
the target deployment will be able to create database using the Cloud Object Storage
provided.

Usage: $0 [OPTIONS]

OPTIONS:
=======
--cos-ssl-certificate | -c   The full path to the public SSL certificate of the Cloud Object Storage (COS).
--deployment-id | -d        The deployment ID of the target Event Store deployment 

Example:
=======
./cp4d_add_COS_cert.sh --deployment-id db2eventstore-1580749232008 --cos-ssl-certificate ~/cos-ssl-cert
USAGE
}

while [ -n "$1" ]
do
   case $1 in
      --cos-ssl-certificate|-c)
         COS_CERT_PATH=$2
         shift 2
         ;;
      --deployment-id |-d)
         DEPLOYMENT_ID=$2
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
      exit ${RES}
   else
      # print the current command if succeeded
      log_info "$COMMAND"
   fi
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TIMESTAMP=`date "+%Y-%m-%d-%H.%M.%S"`
TEMP_SECRET_YAML="${SCRIPT_DIR}/temp_cos_secret_${TIMESTAMP}.yaml"

if [ -z "${DEPLOYMENT_ID}" ]; then
   log_error "Deployment ID must be provided with --deployment-id flag."
   usage >&2
   exit 1
fi

if [ -z "${COS_CERT_PATH}" ]; then
   log_error "Public SSL certificate of the Cloud Object Storage (COS) used \
in Event Store installation must be provided with --cos-ssl-certificate flag."
   usage >&2
   exit 1
fi

if [ ! -f "${COS_CERT_PATH}" ]; then
   log_error "${COS_CERT_PATH} is not a valid file."
   usage >&2
   exit 1
fi

openssl verify ${COS_CERT_PATH}
check_errors $? "Validating SSL certificate using openssl" "Ensure the provided SSL certificate is valid."

COS_SECRET_NAME=$(oc get secret | grep -i $DEPLOYMENT_ID | grep "cos-ssl-certificate-secrets" | awk {'print $1'})
TARGET_COS_SECRET_NAME="${DEPLOYMENT_ID}-cos-ssl-certificate-secrets"

if [ -z "${COS_SECRET_NAME}" ]; then
   log_error "Kubernetes secret: '${TARGET_COS_SECRET_NAME}' doesn't exist."
   log_error "Please ensure:  "
   log_error "  - You have logged in the correct openshift project."
   log_error "  - Event Store deployment of ${DEPLOYMENT_ID} is not in error state."
   usage >&2
fi

log_info "Preparing $TARGET_COS_SECRET_NAME with provided COS SSL certificate..."
touch "${TEMP_SECRET_YAML}"
check_errors $? "Creating temporary secret definition".

oc get secret ${COS_SECRET_NAME} -o yaml > "${TEMP_SECRET_YAML}"

ENCODED_CERT_CONTENT=$(cat ${COS_CERT_PATH} | base64 | tr -d '\n')
sed -ni '/apiVersion/{p;:a;N;/kind:/!ba;s/.*\n/'"data:\n  cos-ssl-cert: $ENCODED_CERT_CONTENT"'\n/};p' "${TEMP_SECRET_YAML}"
check_errors $? "Adding encoded COS SSL certificate to secret definition"

oc apply -f "${TEMP_SECRET_YAML}"
check_errors $? "Updating secret to include COS SSL certificate..."
rm -f ${TEMP_SECRET_YAML}

log_passed "COS SSL certificate is successfully added to the deployment: ${DEPLOYMENT_ID}."
