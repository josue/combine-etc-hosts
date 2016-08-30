#/bin/bash -x

###
#     Repo: https://github.com/josue/combine-etc-hosts
# Authored: Josue Rodriguez <code@josuerodriguez.com>
#  Created: 2016-08-12
###

### --------------- methods --------------- ###
verify_sudo() {
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root in order to update /etc/hosts file." 
     exit 1
  fi

  backup_original_host_file
}

backup_original_host_file() {
  BACKUP_ORIGINAL_HOST="hosts.backup"

  if [ ! -f "${BACKUP_ORIGINAL_HOST}" ]; then
    echo "----- [First-Time Execution -- Notice] ---------------------"
    echo "Your original ${ETC_HOSTS} is being backed-up:"

    cat ${ETC_HOSTS} > ${BACKUP_ORIGINAL_HOST}
    echo "--> Backed-up contents to file: ${BACKUP_ORIGINAL_HOST}"

    if [ ! -f "${LIST_PATH}/localhost" ]; then
      cat ${ETC_HOSTS} > ${LIST_PATH}/localhost
      echo "--> Copied contents to new list: ${LIST_PATH}/localhost"
    fi

    echo "------------------------------------------------------------"
    echo
  fi

  # if 'lists/localhost' doesn't exist then create it:
  if [ ! -f "${LIST_PATH}/localhost" ]; then
    touch "${LIST_PATH}/localhost"
  fi
}

whitelist_domain() {
  DOMAIN=$1
  RE_DOMAIN="${DOMAIN/./\.}"
  FIND_FILES=`grep -ri "${DOMAIN}" ${LIST_PATH}/* | egrep -v ":[#]+[0-9]+\.[0-9]+" | awk -F':' '{ print $1 }' | sort -u`

  if [ "$FIND_FILES" != "" ]; then
    echo "Whitelisting domain: ${DOMAIN}"
    echo
    for FILE in $FIND_FILES
    do
      echo "Updating: ${FILE}"
      sed "s/\(.*${RE_DOMAIN}.*\)/#\1/g" ${FILE} > ${FILE}.wl_updated
      rm ${FILE}
      mv ${FILE}.wl_updated ${FILE}
    done
  else
    echo "No files found with this domain '${DOMAIN}' enabled."
    echo

    FIND_WHITELISTED=`grep -l "^#.*${RE_DOMAIN}" ${LIST_PATH}/*`
    for WH_FILE in $FIND_WHITELISTED;
    do
      echo "Already whitelisted in file: ${WH_FILE}"
    done
  fi
}

blacklist_domain() {
  DOMAIN=$1
  RE_DOMAIN="${DOMAIN/./\.}"
  FIND_FILES=`grep -ri "${DOMAIN}" ${LIST_PATH}/* | egrep ":[#]+[0-9]+\.[0-9]+" | awk -F':' '{ print $1 }' | sort -u`

  if [ "$FIND_FILES" != "" ]; then
    echo "Blacklisting domain: ${DOMAIN}"
    echo
    for FILE in $FIND_FILES
    do
      echo "Updating: ${FILE}"
      sed "s/^#\(.*${RE_DOMAIN}.*\)/\1/g" ${FILE} > ${FILE}.bl_updated
      rm ${FILE}
      mv ${FILE}.bl_updated ${FILE}
    done
  else
    echo "No files found with this domain '${DOMAIN}' disabled."
    echo

    FIND_BLACKLISTED=`grep -l ".*${RE_DOMAIN}" ${LIST_PATH}/*`

    if [ "$FIND_BLACKLISTED" != "" ]; then
      for BL_FILE in $FIND_BLACKLISTED;
      do
        echo "Already blacklisted in file: ${BL_FILE}"
      done
    else
      echo "Added domain to blacklist file: ${BLACKLIST_FILE}"
      echo "127.0.0.1 ${DOMAIN}" >> ${BLACKLIST_FILE}
    fi
  fi
}

find_domain() {
  DOMAIN=$1
  FIND_FILES=`grep -l "${DOMAIN}" ${LIST_PATH}/*`

  if [ "$FIND_FILES" != "" ]; then
    echo "Found domain '${DOMAIN}' in files:"
    echo
    for FILE in $FIND_FILES;
    do
      echo "- ${FILE}"
    done
  else
    echo "No files found with domain: ${DOMAIN}"
  fi
}

add_files() {
  FILENAMES=${1:-''}

  echo "### ---- Modified on `date` via script: `pwd`/${SCRIPT_NAME} ----- ###" > ${HOSTS_COMBINED}

  for FILE in ${FILENAMES}
  do
    echo "--> ${FILE}"
    cat ${FILE} >> ${HOSTS_COMBINED}
  done

  cat ${HOSTS_COMBINED} > ${ETC_HOSTS}

  echo
  echo "File Size: `ls -lh ${ETC_HOSTS} | awk '{print $5}'`"
  echo "Total Addresses: `egrep -e '^[0-9]{1,3}\.[0-9]{1,3}\.' ${ETC_HOSTS} | wc -l | awk '{print $1}'`"

  rm -rf ${HOSTS_COMBINED}
}

run_and_check_cases() {
  case "$1" in
    "-a")
        verify_sudo
        echo "Adding All Lists:"
        echo
        add_files "${LOCALHOST_FILE} ${LS_FILENAMES}"
        ;;

    "-f")
        verify_sudo
        echo "Adding only file: ${2}"
        echo
        add_files "${2}"
        ;;

    "-wl")
        whitelist_domain "${2}"
        ;;

    "-bl")
        blacklist_domain "${2}"
        ;;

    "-d")
        find_domain "${2}"
        ;;

    "-r" | "-l")
        verify_sudo
        echo "Reseting to file: ${LOCALHOST_FILE}"
        echo
        add_files ${LOCALHOST_FILE}
        ;;

    "-h" | *)
        echo "${HELP_INFO}"
        echo
        ;;
  esac
  echo
}

### --------------- parameters & variables --------------- ###
SCRIPT_NAME=`basename "$0"`
ETC_HOSTS="/etc/hosts"
HOSTS_COMBINED="hosts.combined"

# Get given prefix:
if [ "${2}" = "-p" ] && [ "${3}" != "" ]; then
    LIST_PATH="${3}"
else
    LIST_PATH="lists" # default
fi

# Get pattern-matching filenames
if [ "${2}" = "-m" ] && [ "${3}" != "" ]; then
    LOCALHOST_FILE=""
    LS_FILENAMES="`ls ${3}`"
else
    # standard files
    LOCALHOST_FILE="${LIST_PATH}/localhost"
    LS_FILENAMES="`ls ${LIST_PATH}/* | grep -v "${LOCALHOST_FILE}" | grep -v "${LIST_PATH}/empty" | sort -f`"
fi

BLACKLIST_FILE="${LIST_PATH}/blacklist"

HELP_INFO="Usage: ${0} {option}

  Options:

    -a            -- Add all files from directory path '${LIST_PATH}' (default option)

    -p {path}     -- Search for files matching a given pattern.

    -m {pattern}  -- Search a different directory path. (default: ${LIST_PATH})

    -f {filename} -- Add specific file only.

    -d {domain}   -- Find specific domain in files.

    -wl {domain}  -- Whitelist specific domain.

    -bl {domain}  -- Blacklist specific domain.

    -r, -l        -- Reset to standard '${LOCALHOST_FILE}' listing only.

    -h            -- This message :)


  Lists:

  All list files should go in the default the directory 'lists', but you 
  can always adjust the path by using the flag '-p' for pattern-matching 
  a directory or filenames.
"

### --------------- execution path --------------- ###
run_and_check_cases ${*}
