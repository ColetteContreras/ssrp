#!/bin/bash

# If not specify, default meaning of return value:
# 0: Success
# 1: System error
# 2: Application error
# 3: Network error

CUR_VER=""
NEW_VER=""
ARCH=""
VDIS="64"
ZIPFILE="/tmp/ssrp/ssrp.zip"
ssrp_RUNNING=0
VSRC_ROOT="/tmp/ssrp"
EXTRACT_ONLY=0
ERROR_IF_UPTODATE=0

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

SYSTEMCTL_CMD=$(command -v systemctl 2>/dev/null)
SERVICE_CMD=$(command -v service 2>/dev/null)

CHECK=""
FORCE=""
HELP=""

#######color code########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message


#########################
while [[ $# > 0 ]];do
    key="$1"
    case $key in
        -p|--proxy)
        PROXY="-x ${2}"
        shift # past argument
        ;;
        -h|--help)
        HELP="1"
        ;;
        -f|--force)
        FORCE="1"
        ;;
        -c|--check)
        CHECK="1"
        ;;
        --remove)
        REMOVE="1"
        ;;
        --version)
        VERSION="$2"
        shift
        ;;
        --extract)
        VSRC_ROOT="$2"
        shift
        ;;
        --extractonly)
        EXTRACT_ONLY="1"
        ;;
        -l|--local)
        LOCAL="$2"
        LOCAL_INSTALL="1"
        shift
        ;;
        --errifuptodate)
        ERROR_IF_UPTODATE="1"
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done

###############################
colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

sysArch(){
    ARCH=$(uname -m)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="32"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="arm"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="arm64"
    elif [[ "$ARCH" == *"mips64le"* ]]; then
        VDIS="mips64le"
    elif [[ "$ARCH" == *"mips64"* ]]; then
        VDIS="mips64"
    elif [[ "$ARCH" == *"mipsle"* ]]; then
        VDIS="mipsle"
    elif [[ "$ARCH" == *"mips"* ]]; then
        VDIS="mips"
    elif [[ "$ARCH" == *"s390x"* ]]; then
        VDIS="s390x"
    elif [[ "$ARCH" == "ppc64le" ]]; then
        VDIS="ppc64le"
    elif [[ "$ARCH" == "ppc64" ]]; then
        VDIS="ppc64"
    fi
    return 0
}

downloadssrp(){
    rm -rf /tmp/ssrp
    mkdir -p /tmp/ssrp
    colorEcho ${BLUE} "Downloading ssrp."
    DOWNLOAD_LINK="https://github.com/ColetteContreras/ssrp/releases/download/${NEW_VER}/ssrp-linux-${VDIS}.zip"
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho ${RED} "Failed to download! Please check your network or try again."
        return 3
    fi
    return 0
}

installSoftware(){
    COMPONENT=$1
    if [[ -n `command -v $COMPONENT` ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        colorEcho ${RED} "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        return 1 
    fi
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        colorEcho ${BLUE} "Updating software repo"
        $CMD_UPDATE      
        SOFTWARE_UPDATED=1
    fi

    colorEcho ${BLUE} "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to install ${COMPONENT}. Please install it manually."
        return 1
    fi
    return 0
}

# return 1: not apt, yum, or zypper
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    elif [[ -n `command -v zypper` ]]; then
        CMD_INSTALL="zypper -y install"
        CMD_UPDATE="zypper ref"
    else
        return 1
    fi
    return 0
}

extract(){
    colorEcho ${BLUE}"Extracting ssrp package to /tmp/ssrp."
    mkdir -p /tmp/ssrp
    unzip $1 -d ${VSRC_ROOT}
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to extract ssrp."
        return 2
    fi
    if [[ -d "/tmp/ssrp/ssrp-${NEW_VER}-linux-${VDIS}" ]]; then
      VSRC_ROOT="/tmp/ssrp/ssrp-${NEW_VER}-linux-${VDIS}"
    fi
    return 0
}


# 1: new ssrp. 0: no. 2: not installed. 3: check failed. 4: don't check.
getVersion(){
    if [[ -n "$VERSION" ]]; then
        NEW_VER="$VERSION"
        if [[ ${NEW_VER} != v* ]]; then
          NEW_VER=v${NEW_VER}
        fi
        return 4
    else
        VER=`/usr/bin/ssrp/ssrp -version 2>/dev/null`
        RETVAL="$?"
        CUR_VER=`echo $VER | head -n 1 | cut -d " " -f2`
        if [[ ${CUR_VER} != v* ]]; then
            CUR_VER=v${CUR_VER}
        fi
        TAG_URL="https://api.github.com/repos/ColetteContreras/ssrp/releases/latest"
        NEW_VER=`curl ${PROXY} -s ${TAG_URL} --connect-timeout 10| grep 'tag_name' | head -1 | cut -d\" -f4`
        if [[ ${NEW_VER} != v* ]]; then
          NEW_VER=v${NEW_VER}
        fi
        if [[ $? -ne 0 ]] || [[ $NEW_VER == "" ]]; then
            colorEcho ${RED} "Failed to fetch release information. Please check your network or try again."
            return 3
        elif [[ $RETVAL -ne 0 ]];then
            return 2
        elif [[ "$NEW_VER" != "$CUR_VER" ]];then
            return 1
        fi
        return 0
    fi
}

stopssrp(){
    colorEcho ${BLUE} "Shutting down ssrp service."
    if [[ -n "${SYSTEMCTL_CMD}" ]] || [[ -f "/lib/systemd/system/ssrp.service" ]] || [[ -f "/etc/systemd/system/ssrp.service" ]]; then
        ${SYSTEMCTL_CMD} stop ssrp
    elif [[ -n "${SERVICE_CMD}" ]] || [[ -f "/etc/init.d/ssrp" ]]; then
        ${SERVICE_CMD} ssrp stop
    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to shutdown ssrp service."
        return 2
    fi
    return 0
}

startssrp(){
    if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/ssrp.service" ]; then
        ${SYSTEMCTL_CMD} start ssrp
    elif [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/etc/systemd/system/ssrp.service" ]; then
        ${SYSTEMCTL_CMD} start ssrp
    elif [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/ssrp" ]; then
        ${SERVICE_CMD} ssrp start
    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to start ssrp service."
        return 2
    fi
    return 0
}

copyFile() {
    NAME=$1
    ERROR=`cp "${VSRC_ROOT}/${NAME}" "/usr/bin/${NAME}" 2>&1`
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "${ERROR}"
        return 1
    fi
    return 0
}

makeExecutable() {
    chmod +x "/usr/bin/$1"
}

installssrp(){
    # Install ssrp binary to /usr/bin/ssrp
    copyFile ssrp
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to copy ssrp binary and resources."
        return 1
    fi
    makeExecutable ssrp

    # Install ssrp server config to /etc/ssrp
    if [[ ! -f "/etc/ssrp/ssrp.ini" ]]; then
        mkdir -p /etc/ssrp
        mkdir -p /var/log/ssrp

		cp "${VSRC_ROOT}/ssrp.ini" "/etc/ssrp/"
    fi

    return 0
}


installInitScript(){
    if [[ -n "${SYSTEMCTL_CMD}" ]];then
        if [[ ! -f "/etc/systemd/system/ssrp.service" ]]; then
            if [[ ! -f "/lib/systemd/system/ssrp.service" ]]; then
                cp "${VSRC_ROOT}/ssrp.service" "/etc/systemd/system/"
                cp "${VSRC_ROOT}/ssrp@.service" "/etc/systemd/system/"
                systemctl enable ssrp.service
            fi
        fi
        return
    fi
    return
}

Help(){
    echo "./install-release.sh [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file]"
    echo "  -h, --help            Show help"
    echo "  -p, --proxy           To download through a proxy server, use -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc"
    echo "  -f, --force           Force install"
    echo "      --version         Install a particular version, use --version v3.15"
    echo "  -l, --local           Install from a local file"
    echo "      --remove          Remove installed ssrp"
    echo "  -c, --check           Check for update"
    return 0
}

remove(){
    if [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/etc/systemd/system/ssrp.service" ]];then
        if pgrep "ssrp" > /dev/null ; then
            stopssrp
        fi
        systemctl disable ssrp.service
        rm -rf "/usr/bin/ssrp" "/etc/systemd/system/ssrp.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove ssrp."
            return 0
        else
            colorEcho ${GREEN} "Removed ssrp successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    else
        colorEcho ${YELLOW} "ssrp not found."
        return 0
    fi
}

checkUpdate(){
    echo "Checking for update."
    VERSION=""
    getVersion
    RETVAL="$?"
    if [[ $RETVAL -eq 1 ]]; then
        colorEcho ${BLUE} "Found new version ${NEW_VER} for ssrp.(Current version:$CUR_VER)"
    elif [[ $RETVAL -eq 0 ]]; then
        colorEcho ${BLUE} "No new version. Current version is ${NEW_VER}."
    elif [[ $RETVAL -eq 2 ]]; then
        colorEcho ${YELLOW} "No ssrp installed."
        colorEcho ${BLUE} "The newest version for ssrp is ${NEW_VER}."
    fi
    return 0
}

main() {
    #helping information
    [[ "$HELP" == "1" ]] && Help && return
    [[ "$CHECK" == "1" ]] && checkUpdate && return
    [[ "$REMOVE" == "1" ]] && remove && return
    
    sysArch
    # extract local file
    if [[ $LOCAL_INSTALL -eq 1 ]]; then
        colorEcho ${YELLOW} "Installing ssrp via local file. Please make sure the file is a valid ssrp package, as we are not able to determine that."
        NEW_VER=local
        installSoftware unzip || return $?
        rm -rf /tmp/ssrp
        extract $LOCAL || return $?
        #FILEVDIS=`ls /tmp/ssrp |grep ssrp-v |cut -d "-" -f4`
        #SYSTEM=`ls /tmp/ssrp |grep ssrp-v |cut -d "-" -f3`
        #if [[ ${SYSTEM} != "linux" ]]; then
        #    colorEcho ${RED} "The local ssrp can not be installed in linux."
        #    return 1
        #elif [[ ${FILEVDIS} != ${VDIS} ]]; then
        #    colorEcho ${RED} "The local ssrp can not be installed in ${ARCH} system."
        #    return 1
        #else
        #    NEW_VER=`ls /tmp/ssrp |grep ssrp-v |cut -d "-" -f2`
        #fi
    else
        # download via network and extract
        installSoftware "curl" || return $?
        getVersion
        RETVAL="$?"
        if [[ $RETVAL == 0 ]] && [[ "$FORCE" != "1" ]]; then
            colorEcho ${BLUE} "Latest version ${NEW_VER} is already installed."
            if [[ "${ERROR_IF_UPTODATE}" == "1" ]]; then
              return 10
            fi
            return
        elif [[ $RETVAL == 3 ]]; then
            return 3
        else
            colorEcho ${BLUE} "Installing ssrp ${NEW_VER} on ${ARCH}"
            downloadssrp || return $?
            installSoftware unzip || return $?
            extract ${ZIPFILE} || return $?
        fi
    fi 
    
    if [[ "${EXTRACT_ONLY}" == "1" ]]; then
        colorEcho ${GREEN} "ssrp extracted to ${VSRC_ROOT}, and exiting..."
        return 0
    fi

    if pgrep "ssrp" > /dev/null ; then
        ssrp_RUNNING=1
        stopssrp
    fi
    installssrp || return $?
    installInitScript || return $?

    sed -i "1s|proxypanel|${panel_type:-proxypanel}|g" /etc/ssrp/ssrp.ini
    sed -i "2s|https://www.domain.com|${webapi_host}|g" /etc/ssrp/ssrp.ini
    sed -i "3s|webapi_key=\"\"|webapi_key=\"${webapi_key}\"|g" /etc/ssrp/ssrp.ini
    sed -i "4s|1|${webapi_node_id:-1}|g" /etc/ssrp/ssrp.ini

    colorEcho ${GREEN} "ssrp ${NEW_VER} is installed."

    colorEcho ${BLUE} "Starting ssrp service."
    stopssrp
    startssrp

    rm -rf /tmp/ssrp
    return 0
}

main
