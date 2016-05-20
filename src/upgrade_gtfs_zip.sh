#!/usr/bin/env bash

set -e
set -x

source config.sh

#Retrieve GTFS data for Austin
echo "Downloading GTFS Data..."
curl -L -o $GTFSFILE $GTFSURL
echo "GTFS Data downloaded!"

#Add obastuff directory for bundle data
mkdir -p $TOMCATSERVERFOLDER/obastuff

#Build Transit Bundle Data
echo "Building Transit Bundle Data..."
java -Xmx1G -jar $TRANSITDATABUILDERFILE $GTFSFILE ./$TOMCATSERVERFOLDER/obastuff/$BUNDLEDIR -P tripEntriesFactory.throwExceptionOnInvalidStopToShapeMappingException=false
echo "Built!"

cd $TOMCATSERVERFOLDER/bin/
sh shutdown.sh
cd ../..

#Load Transit Bundle Data into SQL Database
echo "Sending Bundle Data to Postgres Database... (This takes a while)"
java -classpath $DATABASELOADERFILE:$PSQLJDBCDRIVERFILE \
 org.onebusaway.gtfs.GtfsDatabaseLoaderMain \
 --driverClass=org.postgresql.Driver \
 --url=$POSTGRES_URL \
 --username=$POSTGRES_USERNAME \
 --password=$POSTGRES_PASSWORD \
 ./gtfs.zip
echo "Complete!"

cd $TOMCATSERVERFOLDER/bin/
sh startup.sh
sleep 10s
cd ../..
