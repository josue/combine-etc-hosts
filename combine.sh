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

add_files() {
  FILENAMES=${1:-''}

  touch ${HOSTS_COMBINED}

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
    LS_FILENAMES="`ls ${LIST_PATH}/* | grep -v "${LOCALHOST_FILE}" | sort -f`"
fi

HELP_INFO="Usage: ${0} {option}

  \033[1mOptions:\033[0m

    -a            -- Add all files from directory path '${LIST_PATH}' (default option)

    -p {path}     -- Search for files matching a given pattern.

    -m {pattern}  -- Search a different directory path. (default: ${LIST_PATH})

    -f {filename} -- Add specific file only.

    -r, -l        -- Reset to standard '${LOCALHOST_FILE}' listing only.

    -h            -- This message :)


  \033[1mLists:\033[0m

  All list files should go in the default the directory 'lists', but you 
  can always adjust the path by using the flag '-p' for pattern-matching 
  a directory or filenames.
"

### --------------- execution path --------------- ###
run_and_check_cases ${*}
