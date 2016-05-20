#!/usr/bin/env bash

set -e
set -x

source config.sh

echo "OneBusAway Quick Instance Spinup Script"
echo "v0.1"
echo "By Vincent Liao"

mkdir -f obatemp
cd obatemp

# Retrieve Tomcat Server
echo "Downloading Tomcat Server..."
curl -L -o $TOMCATSERVERFILE $TOMCATSERVERURL
echo "Tomcat Server downloaded!"

# Retrieve GTFS data for Austin
echo "Downloading GTFS Data..."
curl -L -o $GTFSFILE $GTFSURL
echo "GTFS Data downloaded!"

# Retrieve GTFS Database Loader
echo "Downloading GTFS Database Loader..."
curl -L -o $DATABASELOADERFILE $DATABASELOADERURL
echo "GTFS Database Loader downloaded!"

# Retrieve Postgres JDBC Driver
echo "Downloading Postgres JDBC Driver..."
curl -L -o $PSQLJDBCDRIVERFILE $PSQLJDBCDRIVERURL
echo "Postgres JDBC Driver downloaded!"

# Retrieve Transit Data Builder
echo "Downloading Transit Data Builder..."
curl -L -o $TRANSITDATABUILDERFILE $TRANSITDATABUILDERURL
echo "Transit Data Builder downloaded!"

# Clone onebusaway-application-modules codebase
echo "Downloading onebusaway-application-modules from github..."
git clone $OBACODEBASEURL
echo "Cloned!"
cd $OBACODEBASEFOLDER
git stash
git stash drop
echo "Reset to master!"
git checkout $OBAVERSIONTAG
cd ..
echo "Set to version 1.1.14!"

# Expand Tomcat Server
echo "Unpacking Tomcat Server..."
tar -zxvf $TOMCATSERVERFILE
echo "Tomcat Unpacked!"

# Add obastuff directory for bundle data
mkdir $TOMCATSERVERFOLDER/obastuff
# Add custom catalina.properties config to add obastuff to classpath
echo "Copying catalina.properties to conf directory..."
cp ../$CATALINAPROPERTIESFILE $TOMCATSERVERFOLDER/conf/
echo "Copied!"
# Add custom users file for management accounts
echo "Copying tomcat-users.xml to conf directory..."
cp ../$TOMCATUSERSFILE $TOMCATSERVERFOLDER/conf
echo "Copied!"

# Build Transit Bundle Data
echo "Building Transit Bundle Data..."
java -Xmx1G -jar $TRANSITDATABUILDERFILE $GTFSFILE ./$TOMCATSERVERFOLDER/obastuff/$BUNDLEDIR -P tripEntriesFactory.throwExceptionOnInvalidStopToShapeMappingException=false
echo "Built!"

# Load Transit Bundle Data into SQL Database
echo "Sending Bundle Data to Postgres Database... (This takes a while)"
java -classpath $DATABASELOADERFILE:$PSQLJDBCDRIVERFILE \
 org.onebusaway.gtfs.GtfsDatabaseLoaderMain \
 --driverClass=org.postgresql.Driver \
 --url=$POSTGRES_URL \
 --username=$POSTGRES_USERNAME \
 --password=$POSTGRES_PASSWORD \
 ./gtfs.zip
echo "Complete!"

# Add JDBC Driver
echo "Copying Postgres JDBC Driver to lib directory..."
cp $PSQLJDBCDRIVERFILE $TOMCATSERVERFOLDER/lib/
echo "Copied!"

echo "Copying custom data-sources.xml files over..."
cp ../xmlfiles/onebusaway-api-webapp/data-sources.xml $OBACODEBASEFOLDER/onebusaway-api-webapp/src/main/resources/
cp ../xmlfiles/onebusaway-transit-data-federation-webapp/data-sources.xml $OBACODEBASEFOLDER/onebusaway-transit-data-federation-webapp/src/main/resources/
cp ../xmlfiles/onebusaway-webapp/data-sources.xml $OBACODEBASEFOLDER/onebusaway-webapp/src/main/resources/
echo "Copied!"

echo "Building onebusaway-transit-data-federation-webapp..."
cd $OBACODEBASEFOLDER/onebusaway-transit-data-federation-webapp/
mvn package
cp target/onebusaway-transit-data-federation-webapp.war ../../$TOMCATSERVERFOLDER/webapps
cd ../..
echo "Built and copied to Tomcat!"

echo "Building onebusaway-api-webapp..."
cd $OBACODEBASEFOLDER/onebusaway-api-webapp/
mvn package
cp target/onebusaway-api-webapp.war ../../$TOMCATSERVERFOLDER/webapps
cd ../..
echo "Built and copied to Tomcat!"

echo "Building onebusaway-webapp..."
cd $OBACODEBASEFOLDER/
mvn -am -pl onebusaway-webapp package
cp onebusaway-webapp/target/onebusaway-webapp.war ../$TOMCATSERVERFOLDER/webapps
cd ..
echo "Built and copied to Tomcat!"

cd $TOMCATSERVERFOLDER/bin/
sh startup.sh
sleep 10s
sh shutdown.sh
cd ../..

echo "Building onebusaway-presentation..."
cd $OBACODEBASEFOLDER/onebusaway-presentation/
mvn package
cd ../onebusaway-webapp
#  java -classpath ../onebusaway-presentation/target/onebusaway-presentation-1.1.15-SNAPSHOT.jar org.onebusaway.presentation.impl.CopyCompiledGwtResourcesMain ../../$TOMCATSERVERFOLDER/webapps/onebusaway-webapp
java -classpath ../onebusaway-presentation/target/onebusaway-presentation-1.1.15-SNAPSHOT.jar org.onebusaway.presentation.impl.CopyCompiledGwtResourcesMain ../../gwtresources
cd ../..
cp -R gwtresources/* $TOMCATSERVERFOLDER/webapps/onebusaway-webapp/
echo "Copied over GWT resources!"

# FIXME: The logrotate comamnd hasn't been tested
echo "Logrotating oba server logs..."
cp logrotate.conf /etc/logrotate.d/tomcat
sudo logrotate --force /etc/logrotate.d/tomcat
cat /etc/logrotate.d/tomcat
echo "Copied logrotate config"
