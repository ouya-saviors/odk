#!/bin/bash

#
# ci.sh - Continuous Integration build script
#

PATH=$PATH:.
SAMPLES="iap-sample-app game-sample ouya-controller-testapp cc-sample"
JARONLY=false
EXPORT=false
RCBUILD=false

[ -z "$BUILD_NUMBER" ] && BUILD_NUMBER=1337
[ -z "$NUMBER" ] && NUMBER=1.0.$BUILD_NUMBER
MAJOR=`echo $NUMBER | sed 's/[^0-9.]*\([0-9]*\)\.\?[^0-9.]*\([0-9]*\)\.\?.*/\1/'`
MINOR=`echo $NUMBER | sed 's/[^0-9.]*\([0-9]*\)\.\?[^0-9.]*\([0-9]*\)\.\?.*/\2/'`

# On the off chance that NUMBER was setup improperly, then set the major/minor to rational values.
[ -z "MAJOR" ] && MAJOR=1
[ -z "MINOR" ] && MINOR=0

# Put it in a single variable that has 2 digits for major, 2 digits for minor and 5 digits for build
NUMBER_CODE=`printf '%g%02g%05g' $MAJOR $MINOR $BUILD_NUMBER`

usage() {
    echo "Usage: $0 [-j] [-e] [-r]"
    echo "   -j       Only build ouya-sdk.jar"
    echo "   -e       Copy the final odk.zip artifact to the Builds share"
    echo "   -r       Build is an RC build (used with --export-odk)"
    exit 1
}

while getopts "jer" o ; do
    case "$o" in
        j)
            JARONLY=true
            ;;
        e)
            EXPORT=true
            ;;
        r)
            RCBUILD=true
            ;;
        *)
            usage
            ;;
    esac
done

pushd ../..

if [ -f android_home.sh ] ; then
    . android_home.sh
fi

echo "Creating temp. directory"
mkdir tmp &> /dev/null

checkResult() {
    if [ $? -ne 0 ] ; then
        exit 1
    fi
    if [[ -n "$1" && $1 -ne 0 ]]; then
        exit 1
    fi
}

# Clean up old artifacts
echo "Removing previous artifacts..."
rm odk.zip &> /dev/null
find . -name "ouya-sdk.jar" -print -delete
if [ -d javadoc ] ; then
    echo "Removing previous JavaDoc build..."
    rm -rf javadoc &> /dev/null
fi

# Build SDK .JAR file and JavaDocs
pushd ../sdk

# Do the actual build of the SDK, using the new proguard task
gradlew -q clean createFinalRelease docs

# Store the result, since the 'git reset' will change $?
TMP_VAL=$?

checkResult $TMP_VAL
popd

# Proguard has merged the sdk and sdk-shared jars for us, so just use it directly.
cp ../sdk/build/bundles/release/classes_proguarded.jar tmp/ouya-sdk.jar

# Copy the ouya-sdk.jar into the libs folders
echo Copying SDK into sample directories
for sample in $SAMPLES ; do
    dir=Samples/$sample/libs
    if [ ! -d $dir ] ; then
        mkdir $dir
    fi
    cp tmp/ouya-sdk.jar $dir
    checkResult
done
if [ ! -d libs ] ; then
    mkdir libs
fi
cp tmp/ouya-sdk.jar libs/
checkResult
rm -rf tmp

if $JARONLY ; then
    exit 0
fi

# Copy JavaDocs into build folder
cp -R ../sdk/build/docs/javadoc .
checkResult

if [ -f odk.zip ] ; then
    rm odk.zip
fi
zip -r odk.zip * -x ci.sh odk.zip package_ouya_everywhere.sh ouya-everywhere.zip .settings .classpath .project gen out android_home.sh \*build/
checkResult

# Copy odk.zip to the albox share
if $EXPORT ; then
    out=odk
    if $RCBUILD ; then
        out=odk-rc
    fi
    cp odk.zip ~/shared_builds/$out/$out-$NUMBER.zip
    cp odk.zip ~/shared_builds/$out/$out-latest.zip

    # Make sure to save the proguard mappings too.
    mkdir -p ~/shared_builds/$out/mappings
    zip ~/shared_builds/$out/mappings/$out-$NUMBER.mapping.zip ../sdk/build/bundles/release/mapping.txt
fi

popd
