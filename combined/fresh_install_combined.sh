echo "OneBusAway Quick Instance Spinup Script"
echo "v0.1"
echo "By Vincent Liao"

#Edit these URLs as needed
##########################
GTFSURL="https://data.texas.gov/download/r4v4-vz24/application/zip"
GTFSFILE="gtfs.zip"

#Latest transit data bundle builder url can be found at:
#http://developer.onebusaway.org/modules/onebusaway-application-modules/current/downloads.html
TRANSITDATABUILDERURL="http://nexus.onebusaway.org/service/local/artifact/maven/content?r=public&g=org.onebusaway&a=onebusaway-transit-data-federation-builder&c=withAllDependencies&e=jar&v=1.1.14"
TRANSITDATABUILDERFILE="onebusaway-transit-data-federation-builder-1.1.14.jar"
BUNDLEDIR="bundledata"

#Latest database loader url can be found at:
#http://developer.onebusaway.org/modules/onebusaway-gtfs-modules/current/onebusaway-gtfs-hibernate-cli.html
DATABASELOADERURL="http://nexus.onebusaway.org/service/local/artifact/maven/content?r=public&g=org.onebusaway&a=onebusaway-gtfs-hibernate-cli&v=1.3.4"
DATABASELOADERFILE="onebusaway-gtfs-hibernate-cli-1.1.14.jar"

#Latest OBA Combined Webapp can be found at:
#http://developer.onebusaway.org/modules/onebusaway-application-modules/current/downloads.html
OBAWEBAPPURL="http://nexus.onebusaway.org/service/local/artifact/maven/content?r=public&g=org.onebusaway&a=onebusaway-combined-webapp&e=war&c=full&v=1.1.14"
OBAWEBAPPFILE="onebusaway-combined-webapp.war"

#Latest Tomcat Server can be found at:
#http://tomcat.apache.org/index.html
TOMCATSERVERURL="http://mirrors.ocf.berkeley.edu/apache/tomcat/tomcat-9/v9.0.0.M1/bin/apache-tomcat-9.0.0.M1.tar.gz"
TOMCATSERVERFILE="apache-tomcat-9.0.0.M1.tar.gz"
#Folder name is the same as the URL end part without the tar.gz
TOMCATSERVERFOLDER="apache-tomcat-9.0.0.M1"

PSQLJDBCDRIVERURL="https://jdbc.postgresql.org/download/postgresql-9.4.1207.jar"
PSQLJDBCDRIVERFILE="postgresql-9.4.1207.jar"

DATASOURCESXMLFILE="data-sources.xml"
SERVERXMLFILE="server.xml"
CATALINAPROPERTIESFILE="catalina.properties"
##########################

mkdir obatemp
cd obatemp

#Retrieve GTFS data for Austin
echo "Downloading GTFS Data..."
curl -L -o $GTFSFILE $GTFSURL
echo "GTFS Data downloaded!"

#Retrieve Tomcat Server
echo "Downloading Tomcat Server..."
curl -L -o $TOMCATSERVERFILE $TOMCATSERVERURL
echo "Tomcat Server downloaded!"

#Retrieve GTFS Database Loader
echo "Downloading GTFS Database Loader..."
curl -L -o $DATABASELOADERFILE $DATABASELOADERURL
echo "GTFS Database Loader downloaded!"

#Retrieve Transit Data Builder
echo "Downloading Transit Data Builder..."
curl -L -o $TRANSITDATABUILDERFILE $TRANSITDATABUILDERURL
echo "Transit Data Builder downloaded!"

#Retrieve Postgres JDBC Driver
echo "Downloading Postgres JDBC Driver..."
curl -L -o $PSQLJDBCDRIVERFILE $PSQLJDBCDRIVERURL
echo "Postgres JDBC Driver downloaded!"

#Build Transit Bundle Data
echo "Building Transit Bundle Data..."
java -Xmx1G -jar $TRANSITDATABUILDERFILE org.onebusaway.transit_data_federation.bundle.FederatedTransitDataBundleCreatorMain $GTFSFILE ./$TOMCATSERVERFOLDER/obastuff/$BUNDLEDIR -P tripEntriesFactory.throwExceptionOnInvalidStopToShapeMappingException=false
echo "Built!"

#Load Transit Bundle Data into SQL Database
echo "Sending Bundle Data to Postgres Database... (This takes a while)"
java -classpath $DATABASELOADERFILE:$PSQLJDBCDRIVERFILE \
 org.onebusaway.gtfs.GtfsDatabaseLoaderMain \
 --driverClass=org.postgresql.Driver \
 --url=jdbc:postgresql://localhost/oba \
 --username=vincentliao \
 --password="" \
 ./gtfs.zip
echo "Complete!"

#Retrieve OBA Combined Webapp
echo "Downloading OneBusAway Combined Webapp..."
curl -L -o $OBAWEBAPPFILE $OBAWEBAPPURL
echo "OneBusAway Combined Webapp downloaded!"

#Expand Tomcat Server
"https://jdbc.postgresql.org/download/postgresql-9.4.1207.jar"
echo "Unpacking Tomcat Server..."
tar -zxvf $TOMCATSERVERFILE
echo "Tomcat Unpacked!"

#Relocate OBA .war file
echo "Moving OneBusAway Combined Webapp WAR File to webapps directory..."
mv $OBAWEBAPPFILE $TOMCATSERVERFOLDER/webapps/
echo "Moved!"

#Add JDBC Driver
echo "Moving Postgres JDBC Driver to lib directory..."
cp $PSQLJDBCDRIVERFILE $TOMCATSERVERFOLDER/lib/
echo "Copied!"

#Add custom xml config for OBA
mkdir $TOMCATSERVERFOLDER/obastuff
echo "Copying data-sources.xml file to obastuff directory..."
cp ../$DATASOURCESXMLFILE $TOMCATSERVERFOLDER/obastuff/
echo "Copied!"

#Add custom server.xml config to use custom xml config above
echo "Copying server.xml file to conf directory..."
cp ../$SERVERXMLFILE $TOMCATSERVERFOLDER/conf/
echo "Copied!"

#Add custom catalina.properties config to add obastuff to classpath
echo "Copying catalina.properties to conf directory..."
cp ../$CATALINAPROPERTIESFILE $TOMCATSERVERFOLDER/conf/
echo "Copied!"