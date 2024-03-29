VERSIONS[1]=10
VERSIONS[2]=12
VERSIONS[3]=14
VERSIONS[4]=lts
VERSIONS[5]=current


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SCRIPTDIR="dockertests"
cd $DIR
cd ..

for version in "${VERSIONS[@]}"
do
   :
   FV=`echo $version | sed 's/\./_/'`
   DFile="Dockerfile.$FV"
   if [ -f "$SCRIPTDIR/$DFile" ]; then
	   echo "TEST Version: $version"
	   BUILDLOGS="$DIR/dockerbuild.$version.log"
	   rm -f $BUILDLOGS
	   echo "Start build ..."
	   docker build -t=mpneuried.systemhealth.dockertest.$version -f=$SCRIPTDIR/$DFile . > $BUILDLOGS
	   echo "Run test ..."
	   docker run --name=mpneuried.systemhealth.dockertest.$version mpneuried.systemhealth.dockertest.$version >&2
	   echo "Remove container ..."
	   docker rm mpneuried.systemhealth.dockertest.$version >&2
   else
	   echo "Dockerfile '$DFile' not found"
   fi
done
