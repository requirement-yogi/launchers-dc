#!/bin/bash

APP="$1"
APP_VERSION="$2"
LETTER="${APP:0:1}"
QR_VERSION="5.0.10"
MYSQL_VERSION="9.1.0"
JIRA_DBCONFIG_FILE="jira-dbconfig.xml"

if [[ "$APP" == "confluence" ]] ; then
    PORT_INTERNAL="8090"
elif [[ "$APP" == "jira" ]] ; then
    PORT_INTERNAL="8080"
fi
CONTEXT_PATH="/${LETTER}-app"

if [[ "$APP" == "confluence" ]] ; then
    if [[ "$2" == "7.19."* ]] ; then
        PORT_HTTP="2000"
        PORT_DEBUG="5005"
        PORT_DB="5401"
        JDK="jdk11"
        BASE_IMAGE="eclipse-temurin:11"
    elif [[ "$2" == "8.5."* ]] ; then
        PORT_HTTP="2001"
        PORT_DEBUG="5006"
        PORT_DB="5402"
        JDK="jdk11"
        BASE_IMAGE="eclipse-temurin:11"
    elif [[ "$2" == "8.8."* ]] ; then
        PORT_HTTP="2002"
        PORT_DEBUG="5007"
        PORT_DB="5402"
        JDK="jdk11"
        BASE_IMAGE="eclipse-temurin:11"
    elif [[ "$2" == "8.9."* ]] ; then
        PORT_HTTP="2003"
        PORT_DEBUG="5008"
        PORT_DB="5403"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "9.0."* ]] ; then
        PORT_HTTP="2004"
        PORT_DEBUG="5009"
        PORT_DB="5404"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "9.1."* ]] ; then
        PORT_HTTP="2010"
        PORT_DEBUG="5014"
        PORT_DB="5410"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "9.2."* ]] ; then
        PORT_HTTP="2011"
        PORT_DEBUG="5015"
        PORT_DB="5411"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "9.3."* ]] ; then
        PORT_HTTP="2012"
        PORT_DEBUG="5016"
        PORT_DB="5412"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "9.4."* ]] ; then
        PORT_HTTP="2013"
        PORT_DEBUG="5017"
        PORT_DB="5413"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    else
        echo
        echo "Unknown Confluence version: $2"
        echo "See https://hub.docker.com/r/atlassian/confluence/tags"
        echo "https://www.atlassian.com/software/confluence/download-archives"
        echo
        exit 1
    fi

elif [[ "$APP" == "jira" ]] ; then
    if [[ "$2" == "9.4."* ]] ; then
        PORT_HTTP="2005"
        PORT_DEBUG="5010"
        PORT_DB="5405"
        JDK="jdk11"
        BASE_IMAGE="eclipse-temurin:11"
    elif [[ "$2" == "9.12."* ]] ; then
        PORT_HTTP="2006"
        PORT_DEBUG="5011"
        PORT_DB="5406"
        JDK="jdk11"
        BASE_IMAGE="eclipse-temurin:11"
    elif [[ "$2" == "9.17."* ]] ; then
        PORT_HTTP="2008"
        PORT_DEBUG="5012"
        PORT_DB="5408"
        # It seems Jira 9.15.0 and above were only published as JDK 11, surprisingly:
        # https://hub.docker.com/r/atlassian/jira-software/tags?page=&page_size=&ordering=&name=9.15.0-jdk
        JDK="jdk11"
        BASE_IMAGE="eclipse-temurin:11"
    elif [[ "$2" == "10.0."* ]] ; then
        PORT_HTTP="2009"
        PORT_DEBUG="5013"
        PORT_DB="5409"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "10.3."* ]] ; then
        PORT_HTTP="2030"
        PORT_DEBUG="5030"
        PORT_DB="5430"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "10.4."* ]] ; then
        PORT_HTTP="2031"
        PORT_DEBUG="5031"
        PORT_DB="5431"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    elif [[ "$2" == "10.5."* ]] ; then
        PORT_HTTP="2032"
        PORT_DEBUG="5032"
        PORT_DB="5432"
        JDK="jdk17"
        BASE_IMAGE="eclipse-temurin:17"
    else
        echo
        echo "Unknown Jira version: $2"
        echo "See https://hub.docker.com/r/atlassian/jira-software"
        echo "https://www.atlassian.com/software/jira/download-archives"
        echo
        exit 1
    fi
elif [[ -n "$APP" ]] ; then
    echo "App not supported: $APP"
    exit 1
else
    echo
    echo "Usage: ./build-image.sh ( confluence | jira ) ( 7.19.0 | 8.5.0 | ...) [--apple-but-skip-building|...]"
    echo "       --apple-but-skip-building just rebuilds the docker-compose.yml, but not the image"
    echo "       --mysql builds the Jira image for MySQL. For Confluence, you can just change the docker-compose.yml"
    echo "       --skip-etchosts By default, the script fails if the user forgot to add the new hostname in /etc/hosts,"
    echo "                       but this flag is able to skip this check."
    echo
    exit 1
fi

set -u
set -e

APPLE="false"
SKIP_BUILDING="false"
APPLE_SUFFIX=""
SKIP_ETC_HOSTS="false"
if [[ $(uname -m) == 'arm64' ]]; then
    # It's an M-series processor
    APPLE="true"
    APPLE_SUFFIX="-apple"
fi
if [[ $# -eq 3 ]] ; then
    if [[ "$3" == "--apple-but-skip-building" ]] ; then
        APPLE="true"
        APPLE_SUFFIX="-apple"
        SKIP_BUILDING="true"
    elif [[ "$3" == "--skip-etchosts" ]] ; then
        SKIP_ETC_HOSTS="true"
    fi
fi

# We set "proxy" variables for the reverse http proxy. By default you will access it locally on your computer,
# but if you are performing DC tests, you will override those values to execute from a domain name.
if [[ -z "${PROXY_DOMAIN-}" ]] ; then
    PROXY_DOMAIN="${LETTER}${APP_VERSION}.local"
fi
if [[ -z "${PROXY_PORT-}" ]] ; then
    PROXY_PORT="${PORT_HTTP}"
fi
if [[ "${PROXY_HTTPS-}" == "true" ]] ; then
    PROXY_SCHEME="https"
    PROXY_SECURE="true"
else
    PROXY_SCHEME="http"
    PROXY_SECURE="false"
fi

echo "APP=$APP"
echo "LETTER=$LETTER"
echo "PORT_INTERNAL=$PORT_INTERNAL"
echo "PORT_HTTP=$PORT_HTTP"
echo "PROXY_DOMAIN=$PROXY_DOMAIN"
echo "PROXY_PORT=$PROXY_PORT"
echo "PROXY_SCHEME=$PROXY_SCHEME"
echo "PROXY_SECURE=$PROXY_SECURE"
echo "PORT_DEBUG=$PORT_DEBUG"
echo "PORT_DB=$PORT_DB"
echo "APP_VERSION=$APP_VERSION"
echo "JDK=$JDK"
echo "APPLE=$APPLE"
echo "SKIP_BUILDING=$SKIP_BUILDING"
echo "APPLE_SUFFIX=$APPLE_SUFFIX"
echo "BASE_IMAGE=$BASE_IMAGE"
echo "JIRA_DBCONFIG_FILE=$JIRA_DBCONFIG_FILE"

#### First, download the jar

if [ ! -f "./docker/tmp/quickreload-${QR_VERSION}.jar" ] || [ ! -f "./docker/tmp/quickreload.properties" ] ; then

    QR_PATH="${HOME}/.m2/repository/com/atlassian/labs/plugins/quickreload/${QR_VERSION}/quickreload-${QR_VERSION}.jar"
    echo "Downloading quickreload-${QR_VERSION}.jar"

    [ -d "./docker/tmp" ] || mkdir -p docker/tmp

    if [ ! -f "${QR_PATH}" ] ; then
        mvn dependency:get \
            -Dartifact=com.atlassian.labs.plugins:quickreload:${QR_VERSION} \
            -Dtransitive=false \
            -DrepoUrl=https://packages.atlassian.com/mvn/maven-atlassian-external
    fi

    cp ${QR_PATH} ./docker/tmp/quickreload-${QR_VERSION}.jar # Will be uploaded into the VM
    echo "/plugin" > ./docker/tmp/quickreload.properties # Necessary to build the image
fi

## Download the MySQL driver
MYSQL_JAR_LOCATION="docker/tmp/mysql-connector-j-${MYSQL_VERSION}.jar"
if [ ! -f "${MYSQL_JAR_LOCATION}" ] ; then
    cd docker/tmp
    [ -f "docker/tmp/mysql-connector-j-${MYSQL_VERSION}.tar.xf" ] || curl -O https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-j-${MYSQL_VERSION}.tar.gz
    tar xf mysql-connector-j-${MYSQL_VERSION}.tar.gz
    cp mysql-connector-j-${MYSQL_VERSION}/mysql-connector-j-${MYSQL_VERSION}.jar ./
    cd ../..
    [ -f "${MYSQL_JAR_LOCATION}" ] || (echo "Can't find the jar at location: ${MYSQL_JAR_LOCATION}" ; exit 1)
fi


if [[ $APPLE == "true" && $SKIP_BUILDING == "false" ]] ; then

    echo "Rebuilding the Atlassian image, but for Apple silicon"

    if [[ "$APP" == "confluence" ]] ; then
        if [[ ! -d "./docker/tmp/confluence-docker-builder" ]] ; then
            cd docker/tmp
            git clone --recurse-submodule https://bitbucket.org/atlassian-docker/docker-atlassian-confluence-server.git confluence-docker-builder
        else
            cd docker/tmp/confluence-docker-builder
            git pull
        fi
        docker build --tag "atlassian/${APP}:${APP_VERSION}-${JDK}${APPLE_SUFFIX}" --build-arg CONFLUENCE_VERSION=$APP_VERSION --build-arg "BASE_IMAGE=${BASE_IMAGE}" .
        cd -

    elif [[ "$APP" == "jira" ]] ; then
        # Doesn't work? Check with https://github.com/collabsoft-net/example-jira-app-with-docker-compose/blob/AppleSilicon/start.sh
        if [[ ! -d "./docker/tmp/jira-docker-builder" ]] ; then
            cd docker/tmp
            git clone --recurse-submodule https://bitbucket.org/atlassian-docker/docker-atlassian-jira.git jira-docker-builder
        else
            cd docker/tmp/jira-docker-builder
            git pull
        fi
        #                                                                                             APP_VERSION <- May not be the right name. Is it JIRA_VERSION?
        docker build --tag "atlassian/jira-software:${APP_VERSION}-${JDK}${APPLE_SUFFIX}" --build-arg JIRA_VERSION=$APP_VERSION --build-arg "BASE_IMAGE=${BASE_IMAGE}" .
        cd -

    fi
fi

#### Build the image

cd docker
docker build \
    --build-arg "APP_VERSION=${APP_VERSION}" \
    --build-arg "JDK=${JDK}" \
    --build-arg "APPLE_SUFFIX=${APPLE_SUFFIX}" \
    --build-arg "QR_VERSION=${QR_VERSION}" \
    --build-arg "MYSQL_JAR_LOCATION=${MYSQL_JAR_LOCATION}" \
    --build-arg "MYSQL_VERSION=${MYSQL_VERSION}" \
    --build-arg "JIRA_DBCONFIG_FILE=${JIRA_DBCONFIG_FILE}" \
    -t "yogi:${APP}-${APP_VERSION}${APPLE_SUFFIX}" \
    --file "Dockerfile-$APP" \
    .
cd -

#### Now, create a directory with a specific docker-compose.yml

export APP
export LETTER
export CONTEXT_PATH
export PROXY_DOMAIN
export PROXY_PORT
export PROXY_SCHEME
export PROXY_SECURE
export PORT_DEBUG
export PORT_DB
export PORT_HTTP
export APP_VERSION
export APPLE_SUFFIX
export APPLE_SUFFIX
export PORT_INTERNAL
export DOLLAR="$"
export QR_VERSION
export MYSQL_JAR_LOCATION
export MYSQL_VERSION

FOLDER_NAME="${APP}-${APP_VERSION}${APPLE_SUFFIX}"

[ -d "./${FOLDER_NAME}" ] || mkdir ${FOLDER_NAME}

# It interprets the variables
envsubst < docker/docker-compose-template-${APP}.yml > ${FOLDER_NAME}/docker-compose.yml
envsubst < docker/app-nginx.conf > ${FOLDER_NAME}/app-nginx.conf
envsubst < docker/image-information.md > ${FOLDER_NAME}/README.md


# Necessary to connect Confluence and Jira together
docker network create shared-network 2> /dev/null || true

echo
echo "=== Created: ${FOLDER_NAME}/docker-compose.yml ==="
echo

echo "cd ${FOLDER_NAME}"
echo "docker compose up --detach"
echo "tail -f logs/atlassian-$APP.log"
echo "${PROXY_SCHEME}://${PROXY_DOMAIN}:${PROXY_PORT}${CONTEXT_PATH}"
echo "Ready."

if [[ "$SKIP_ETC_HOSTS" == "false" ]] && ! grep -q "${LETTER}${APP_VERSION}\.local" /etc/hosts ; then
    echo -e "Missing entry in /etc/hosts. Please enter:\n127.0.0.1 ${LETTER}${APP_VERSION}.local"
    exit 9
fi
