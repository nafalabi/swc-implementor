#!/usr/bin/env bash

ACTION=$1
ROOT_DIR=$2
TRANSFORM_FILE_LIST='filetotransform.txt'
WEBPACK_FILE_NAME='webpack.common.js'

printHelp() {
    if [[ $1 ]]; then
        echo "Missing arguments $1"
    fi
    echo
    echo "Usage: $(basename $0) [options] ACTION ROOT_DIR"
    echo
    printf "Actions:\n"
    printf "\timplements\timplement swc in the specified dir\n"
    printf "\treset     \ttakeout swc implementation\n"
    echo
    echo -e "Options:"
    echo -e "\t-w webpack_file_name\tspecify webpack file name within ROOT_DIR (default 'webpack.common.js')"
    echo
    echo
    exit 2
}

implements () {
    filelist=$(grep -r -e "export default\s*$" $ROOT_DIR | sed "s/:.*$//")
    echo $filelist > $TRANSFORM_FILE_LIST;

    if ! [[ -x $(command -v jscodeshift) ]]; then
        printf "jscodeshift does not exist, installing...\n\n"
        npm i -g jscodeshift@v0.14
        printf "\nCompleted installing jscodeshift\n"
    fi

    echo -e "\nRunning transform code...\n"
    jscodeshift -t transformCode.js $filelist > /dev/null 2>&1
    echo "Success transforming Code"

    echo "Updating webpack config..."
    cp ./.swcrc $ROOT_DIR/.
    webpackpath=$(find $ROOT_DIR -iname $WEBPACK_FILE_NAME)
    jscodeshift -t transformWebpack.js $webpackpath > /dev/null 2>&1
    echo "Success updating webpack config"

    echo "Installing dependencies (@swc/core & swc-loader)..."
    cd $ROOT_DIR
    npm i -D @swc/core@v1.3.29 swc-loader@v0.2.3 > /dev/null 2>&1
    echo "Success installing dependencies"

    echo
    echo "Script Finished."
    echo
}

reset () {
    filelist=$(cat $TRANSFORM_FILE_LIST)
    cd $ROOT_DIR;
    echo -e "\nRecovering files...\n"
    git checkout $filelist
    webpackpath=$(find $ROOT_DIR -iname $WEBPACK_FILE_NAME)
    git checkout $webpackpath
    rm .swcrc
    echo "Uninstalling dependencies (@swc/core & swc-loader)..."
    npm uninstall @swc/core swc-loader > /dev/null 2>&1
    echo "Success uninstalling dependencies"

    echo
    echo "Script Finished."
    echo
}

while getopts "h:w:" option; do
    case "$option" in
        w) WEBPACK_FILE_NAME=$OPTARG;;
        h) printHelp; exit;;
        ?) echo -e "\nInvalid Options"; printHelp; exit 2;;
    esac
done

ACTION=${@:$OPTIND:1}
ROOT_DIR=${@:$OPTIND+1:1}

if [[ ! -d $ROOT_DIR ]]; then
    echo -e "\nThe provided ROOT_DIR does not exist!!!\n";
    printHelp;
    exit 2;
fi

case "$ACTION" in
    implements | implement) implements ;;
    reset) reset ;;
    *) echo -e "\nPlease provide a valid ACTION!!!\n"; printHelp; exit 2 ;;
esac

