#!/bin/bash

# This script is intended to streamline the use of docker during development.
# We want to establish and follow some standards for building, running, and
# deploying between GitHub and Docker.  This script should be edited to control that.

# ARGUMENTS:
# "build"   : Build Docker Image
# "run"     : Create Docker Container From Image
# "release" : Tag and push to both GitHub and Docker Hub
# "terminal": Go to a running docker container in the terminal
# "start"   : Start an existing docker container that has been stopped.

set -e

# Project: Don't change this.  It sets the project name, for the purposes of this script,
# to the current directory name (sans the path), which should be the repo name.
PROJECT=${PWD##*/}
echo $PROJECT

# Version (JIRA Ticket Number AND git branch name)
VERSION="(untracked)"
branch_name="$(git symbolic-ref -q HEAD)"
VERSION=${branch_name:11}||$VERSION
echo $VERSION

# Don't change this.  Our base docker images have an
# established user called "rmarkbio" inside the container whose password
# is "##rmarkbio%%".
USER_NAME=rmarkbio

# This is the base docker image that we are starting with
IMAGE_NAME=$PROJECT

# This is the name of your local docker container that you will be developing in.
CONTAINER_NAME=$PROJECT\_$VERSION

# Take a user argument for what kind of docker action we want to do
ACTION=$1
MESSAGE=$2

case $ACTION in

    rmi)
        echo 'rmi: remove docker image'
        docker rmi rmarkbio/$IMAGE_NAME:$VERSION
        ;;

    rm)
        echo 'rm: remove docker container'
        docker rm $CONTAINER_NAME
        ;;

    build)
        echo 'build: Build Docker Image'

        # Build an image tagged with the JIRA ticket version
        docker build -t $USER_NAME/$IMAGE_NAME:$VERSION .
        ;;

    run)
        echo 'run: Create Docker Container From Image'

        # -i for "interactive";
        # -t for "terminal";
        # --net="host" is for accessing the host (system) network from inside the container....
        #              ...which I need to access the bolt address.
        # -v to map the current directory to the container's working directory
        docker run -i -t \
            --entrypoint /bin/bash \
            --net="host" \
            --name=$CONTAINER_NAME \
            -v $PWD:/home/rmarkbio/project \
            -v $PWD/../logs:/home/rmarkbio/logs \
            -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
            $USER_NAME/$IMAGE_NAME:$VERSION
        ;;

    terminal)
        docker exec -it $CONTAINER_NAME /bin/bash
        ;;

    stop)
        docker stop $CONTAINER_NAME
        ;;

    start)
        docker start -ai $CONTAINER_NAME
        ;;

    commit)
        if [ $# -eq 2 ]; then
            echo 'commit'
            echo 'VERSION: '$VERSION
            echo 'MESSAGE: '$MESSAGE

            # Commit message
            COMMIT_MESSAGE=$MESSAGE

            # Git commit
            #git add .
            git commit -am "$VERSION : $COMMIT_MESSAGE"

            # Commit, tag, and push the docker image for this update.
            docker commit $CONTAINER_NAME $USER_NAME/$IMAGE_NAME:$VERSION
            docker tag $USER_NAME/$IMAGE_NAME:$VERSION $USER_NAME/$IMAGE_NAME:latest
        else
            echo 'To commit, enter a commit message as a second argument in quotes.'
        fi
        ;;


    push)

        if [ $# -eq 2 ]; then
            echo 'push: Commit and push to both GitHub and Docker Hub'
            echo 'VERSION: '$VERSION
            echo 'MESSAGE: '$MESSAGE

            # Commit message
            COMMIT_MESSAGE=$MESSAGE

            # Run Doxygen first
            #doxygen Doxyfile

            # Git commit
            #git add .
            git commit -am "$VERSION : $COMMIT_MESSAGE"

            # Push the git branch to the origin
            git push origin $VERSION

            # Commit, tag, and push the docker image for this update.
            docker commit $CONTAINER_NAME $USER_NAME/$IMAGE_NAME:$VERSION
            docker tag $USER_NAME/$IMAGE_NAME:$VERSION $USER_NAME/$IMAGE_NAME:latest
            docker push $USER_NAME/$IMAGE_NAME:latest
            docker push $USER_NAME/$IMAGE_NAME:$VERSION
        else
            echo 'To push, enter a commit message as a second argument in quotes.'
        fi
        ;;

esac
