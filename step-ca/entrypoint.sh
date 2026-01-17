#!/bin/bash

set -eo pipefail

export STEPPATH="/home/step"
export CONFIG_PATH="/home/step/config/ca.json"
export PASSWD_PATH="/home/step/secrets/password"

declare -ra REQUIRED_INIT_VARS=(
    DOCKER_STEPCA_INIT_NAME
    DOCKER_STEPCA_INIT_DNS_NAMES
)

function generate_password() {
    set +o pipefail
    < /dev/urandom tr -dc '[[:alnum:]]' | head -c40
    echo
    set -o pipefail
}

function step_ca_init() {
    DOCKER_STEPCA_INIT_PROVISIONER_NAME="${DOCKER_STEPCA_INIT_PROVISIONER_NAME:-admin}"
    DOCKER_STEPCA_INIT_ADMIN_SUBJECT="${DOCKER_STEPCA_INIT_ADMIN_SUBJECT:-step}"
    DOCKER_STEPCA_INIT_ADDRESS="${DOCKET_STEPCA_INIT_ADDRESS:-:9000}"
    DOCKER_STEPCA_INIT_ROOT_FILE="${DOCKER_STEPCA_INIT_ROOT_FILE:-'/run/secrets/root_ca.crt'}"
    DOCKER_STEPCA_INIT_KEY_FILE="${DOCKER_STEPCA_INIT_KEY_FILE:-'/run/secrets/root_ca_key'}"
    DOCKER_STEPCA_INIT_KEY_PASSWORD_FILE="${DOCKER_STEPCA_INIT_KEY_PASSWORD_FILE:-'/run/secrets/root_ca_key_password'}"

    local -a setup_args=(
        "--name=${DOCKER_STEPCA_INIT_NAME}"
        "--dns=${DOCKER_STEPCA_INIT_DNS_NAMES}"
        "--provisioner=${DOCKER_STEPCA_INIT_PROVISIONER_NAME}"
        "--password-file=${STEPPATH}/password"
        "--provisioner-password-file=${STEPPATH}/provisioner_password"
        "--address=${DOCKER_STEPCA_INIT_ADDRESS}"
    )
    if [ -n "${DOCKER_STEPCA_INIT_PASSWORD_FILE}" ]; then
        cat < "${DOCKER_STEPCA_INIT_PASSWORD_FILE}" > "${STEPPATH}/password"
        cat < "${DOCKER_STEPCA_INIT_PASSWORD_FILE}" > "${STEPPATH}/provisioner_password"
    elif [ -n "${DOCKER_STEPCA_INIT_PASSWORD}" ]; then
        echo -n "${DOCKER_STEPCA_INIT_PASSWORD}" > "${STEPPATH}/password"
        echo -n "${DOCKER_STEPCA_INIT_PASSWORD}" > "${STEPPATH}/provisioner_password"
    else
        generate_password > "${STEPPATH}/password"
        generate_password > "${STEPPATH}/provisioner_password"
    fi
    if [ -f "${DOCKER_STEPCA_INIT_ROOT_FILE}" ]; then
        setup_args+=("--root=${DOCKER_STEPCA_INIT_ROOT_FILE}")
    fi
    if [ -f "${DOCKER_STEPCA_INIT_KEY_FILE}" ]; then
        setup_args+=("--key=${DOCKER_STEPCA_INIT_KEY_FILE}")
    fi
    if [ -f "${DOCKER_STEPCA_INIT_KEY_PASSWORD_FILE}" ]; then
        setup_args+=("--key-password-file=${DOCKER_STEPCA_INIT_KEY_PASSWORD_FILE}")
    fi
    if [ -n "${DOCKER_STEPCA_INIT_DEPLOYMENT_TYPE}" ]; then
        setup_args+=("--deployment-type=${DOCKER_STEPCA_INIT_DEPLOYMENT_TYPE}")
    fi
    if [ -n "${DOCKER_STEPCA_INIT_WITH_CA_URL}" ]; then
        setup_args+=("--with-ca-url=${DOCKER_STEPCA_INIT_WITH_CA_URL}")
    fi
    if [ "${DOCKER_STEPCA_INIT_SSH}" == "true" ]; then
        setup_args+=("--ssh")
    fi
    if [ "${DOCKER_STEPCA_INIT_ACME}" == "true" ]; then
        setup_args+=("--acme")
    fi
    if [ "${DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT}" == "true" ]; then
        setup_args+=("--remote-management")
        setup_args+=("--admin-subject=${DOCKER_STEPCA_INIT_ADMIN_SUBJECT}")
    fi
    step ca init "${setup_args[@]}"
    echo ""
    if [ "${DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT}" == "true" ]; then
        echo "Remote Management has been enabled."
        echo "👉 Your CA administrative username is: ${DOCKER_STEPCA_INIT_ADMIN_SUBJECT}"
    fi
    echo "👉 Your CA administrative password is: $(< $STEPPATH/provisioner_password )"
    echo "🤫 This will only be displayed once."
    shred -u "${STEPPATH}/provisioner_password"
    mv "${STEPPATH}/password" "${PASSWD_PATH}"
}

function init_if_possible() {
    local missing_vars=0
    for var in "${REQUIRED_INIT_VARS[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars=1
        fi
    done
    if [ "${missing_vars}" -eq 1 ]; then
        >&2 echo "there is no 'ca.json' config file!"
        >&2 echo "please run 'step ca init' or provide configuration via"
        >&2 echo "     'DOCKER_STEPCA_INIT_*' vars"
    else
        step_ca_init "${@}"
    fi
}

if [ ! -f "${STEPPATH}/config/ca.json" ]; then
    init_if_possible
fi

exec "${@}"
