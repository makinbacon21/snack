#!/bin/bash

# snack
# Author:   Thomas Makin <halorocker89@gmail.com>
# Credits:  Pablo Zaidenvoren <pablo@zaiden.com.ar>
#           The Great Wizard Azkali <a.ffcc7@gmail.com>

# I don't feel like messing with other scripts for development
# so here's a nice lil script to prep everything for LineageOS
# development environments

# FOLDER STRUCTURE:
# $ANDROID_BUILD_TOP/.repo/local_manifests/
# |- patches
# |  |- [name].patch
# |  |- ...
# |- default.xml [not used by this script]
# |- README.md [unnecessary]
# |- patchlist
# |- picklist
# |- snack.sh

# ARGS:
# -y       | Auto accept sync prompt
# -n       | Auto reject sync prompt
# -w       | Use local changes (don't clean)
# -h       | Display this message
# -c       | Sanity checker
# -p       | Do not pull latest manifest
# -j <int> | Set jobs/connections to arbitrary value

# Apply patched--CREDIT Pablo Zaidenvoren <pablo@zaiden.com.ar>
# https://github.com/PabloZaiden/switchroot-android-build/blob/master/build-scripts/repopic-and-patch.sh

function applyPatches {
    PATCHES_FILE=$1
    echo "Applying patches from $PATCHES_FILE"

    while read -r line; 
    do
        IFS=',' read -r -a parts <<< "$line"

        if [[ "${parts[2]}" == "git" ]]; 
        then
            echo "Applying patch ${parts[0]} with git am"
            eval "git -C ${ANDROID_BUILD_TOP}/${parts[1]} am ${PATCHDIR}/${parts[0]}"
            cd $ANDROID_BUILD_TOP
        else
            echo "Applying patch ${parts[0]} with Unix patch utility"
            eval "patch -p1 -d ${ANDROID_BUILD_TOP}/${parts[1]} -i ${PATCHDIR}/${parts[0]}"
        fi
    done < $PATCHES_FILE
}

# Apply repopicks--CREDIT Pablo Zaidenvoren <pablo@zaiden.com.ar>
# https://github.com/PabloZaiden/switchroot-android-build/blob/master/build-scripts/repopic-and-patch.sh

function applyRepopicks {
    REPOPICKS_FILE=$1
    echo "Applying repopicks from $REPOPICKS_FILE"

    cd $ANDROID_BUILD_TOP
    while IFS= read -r line; do
        if [[ ${line:0:1} == "\"" ]];
        then
            echo "Picking topic: $line"
            eval "$ANDROID_BUILD_TOP/vendor/lineage/build/tools/repopick.py -f -t $line"
        else
            echo "Picking: $line"
            eval "$ANDROID_BUILD_TOP/vendor/lineage/build/tools/repopick.py -f $line"
        fi

    done < $REPOPICKS_FILE
}

function check {
    if [[ -z $ANDROID_BUILD_TOP ]];
    then
        echo "ANDROID_BUILD_TOP not found--assuming PWD and running envsetup"
        source build/envsetup.sh || echo "envsetup failed--are you in the right directory?"
        exit 0
    elif [[ $ANDROID_BUILD_TOP != $PWD ]];
    then
        echo "\
        ANDROID_BUILD_TOP is not PWD
        Make sure you're in the right directory!"
    fi
    if [[ ! -d "$ANDROID_BUILD_TOP/patches" ]];
    then
        echo "\
        Patch folder not found
        Make sure your manifest has patches!"
    fi
    if [[ ! -f "$ANDROID_BUILD_TOP/patchlist" ]];
    then
        echo "\
        Patch list not found
        Make sure your snack submodule is up to date!"
    fi
    if [[ ! -f "$ANDROID_BUILD_TOP/picklist" ]];
    then
        echo "\
        Pick list not found
        Make sure your snack submodule is up to date!"
    fi
    exit 0
}

function help {
    echo "\
Welcome to snack!
Author:     Thomas Makin <halorocker89@gmail.com>
Credits :   Pablo Zaidenvoren <pablo@zaiden.com.ar>
            The Great Wizard Azkali <a.ffcc7@gmail.com>

-y       | Auto accept sync prompt
-n       | Auto reject sync prompt
-w       | Use local changes (don't clean)
-h       | Display this message
-c       | Sanity checker
-p       | Do not pull latest manifest
-j <int> | Set jobs/connections to arbitrary value"
    
    exit 0
}

# Setup, clean, and update dev environment
function prep {
    export PATCHDIR=$ANDROID_BUILD_TOP/.repo/local_manifests/patches

    if [[ -z $MANIFEST ]];
    then
        git -C $ANDROID_BUILD_TOP/.repo/local_manifests pull --recurse-submodules
    fi

    if [[ -z $CLEAN ]];
    then
        repo forall -c 'git clean -dxf'
        repo forall -c 'git reset --hard'
    fi

    if [[ -z $SYNC ]];
    then
        read -p "Would you like to sync? " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo "Syncing..."
            repo sync --force-sync -j${JOBS}
        fi
    elif [[ $SYNC == true ]];
    then
        echo "Syncing..."
        repo sync --force-sync -j${JOBS}
    fi
}

function usage
{
    echo "Usage: ./snack.sh [-y] [-n] [-w] [-h] [-c] [-p] [-j <int>]"
    exit 1;
}

# ENTRY

while getopts ":ynwhcpj:" o; do
    case "${o}" in
        y)
            echo "Will sync when ready."
            SYNC=true
            ;;
        n)
            echo "Will not sync."
            SYNC=false
            ;;
        w)
            echo "Will use local changes."
            CLEAN=false
            ;;
        h)
            help
            ;;
        c)
            check
            ;;
        p)
            echo "Will not pull latest manifest."
            MANIFEST=false
            ;;
        j)
            if [[ -z $OPTARG ]];
            then
                usage
            fi
            JOBS=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z $JOBS ]];
then
    JOBS=$(($(nproc) - 1)) # Google guidelines for `repo`
fi

if [[ -z $ANDROID_BUILD_TOP ]];
then
    echo "ANDROID_BUILD_TOP not found...assuming PWD"
    source build/envsetup.sh || ANDROID_BUILD_TOP=$PWD
elif [[ $ANDROID_BUILD_TOP != $PWD ]];
then
    echo "ANDROID_BUILD_TOP is not PWD--watch out!"
fi

prep

if [[ -z $CLEAN ]]; then
    applyRepopicks $ANDROID_BUILD_TOP/.repo/local_manifests/picklist
    applyPatches $ANDROID_BUILD_TOP/.repo/local_manifests/patchlist
else
    echo Will not repopick or patch--run without -w to pick and patch
fi
