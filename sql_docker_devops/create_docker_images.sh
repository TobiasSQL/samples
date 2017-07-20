#### Preparation ########################################
# 1. Create Azure Storage Account                       #
# 2. Add a file share to the storage account            #
# 3. Install CIFS to be able to mount the file share    #
# sudo apt-get install cifs-utils                       #
# 4. Create a directory to mount the file share         #
# mkdir /azurebackups                                   #
#########################################################

# Mount Azure file
# Note. Username is the storage account name and password is the "Access key"
sudo mount -t cifs //tobfiledemo.file.core.windows.net/azurebackups /azurebackups -o vers=3.0,username=tobfiledemo,password=3Swmq4jJH+rDnfTBv4eZPwMU1NZvAYD3nYGZ9JtsOLDjbUNCI+HiZ5NNkSeG6VVyvHez0by4KDor9TmOstLlgQ==,dir_mode=0777,file_mode=077 

printf "\n*** Pull and run microsoft/mssql-server-linux Docker image from Docker Hub ***\n"
docker pull microsoft/mssql-server-linux
docker run --name sanitation-station -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Mission-123' -p 1433:1433 -v /azurebackups:/azurebackups -d microsoft/mssql-server-linux 
docker ps

printf "\n*** Restoring production database into sanitation environment ***\n"
sqlcmd -Usa -PMission-123 -i ../sql/Restore_Production_Database_as_Development.sql

printf "\n*** Docker commit to create pre-production image ***\n"
docker commit sanitation-station db-pre-prod:latest
docker images

printf "\n*** Sanitizing production data for development use ***\n"
printf "\n*** Unsanitized data: ***\n"
sqlcmd -Usa -PMission-123 -Q"SELECT TOP 10 FirstName, LastName FROM ContosoUniversity.dbo.Person;"
sqlcmd -Usa -PMission-123 -i ../sql/Sanitize_Production_Database_for_Dev_use.sql
printf "\n*** Sanitized data (using Norwegian encryption): ***\n"
sqlcmd -Usa -PMission-123 -Q"SELECT TOP 10 FirstName, LastName FROM ContosoUniversity.dbo.Person;"

printf "\n*** Docker commit to create big dev image ***\n"
docker commit sanitation-station db-dev-big-tmp:latest
docker images

printf "\n*** Shrinking small dev database ***\n"
sqlcmd -Usa -PMission-123 -i ../sql/Shrink_Development_Database_Small.sql

printf "\n*** Docker commit to create small dev image ***\n"
docker commit sanitation-station db-dev-small-tmp:latest
docker images
docker rm -f sanitation-station

printf "\n*** Flattening small image to reduce size ***\n"
docker run --name tmp-small -d db-dev-small-tmp
docker export tmp-small | docker import - db-dev-small:latest
docker rm -f tmp-small
docker rmi db-dev-small-tmp

printf "\n*** Flattening large image to reduce size ***\n"
docker run --name tmp-big -d db-dev-big-tmp
docker export tmp-big | docker import - db-dev-big:latest
docker rm -f tmp-big
docker rmi db-dev-big-tmp

printf "\n*** Final list of images ***\n"
docker images

printf "\n*** Build and Publish images to registry ***\n"
docker build ./db-dev-small -t db-dev-small:latest
docker build ./db-dev-big -t db-dev-big:latest

docker tag db-dev-small:latest ContosoRegistry.azurecr.io/db-dev-small:latest
#docker push ContosoRegistry.azurecr.io/db-dev-small:latest

docker tag db-dev-big:latest ContosoRegistry.azurecr.io/db-dev-big:latest
#docker push ContosoRegistry.azurecr.io/db-dev-big:latest

docker tag db-pre-prod:latest ContosoRegistry.azurecr.io/db-pre-prod:latest
#docker push ContosoRegistry.azurecr.io/db-pre-prod:latest

#docker run --name db-big -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Mission-123' -p 1433:1433 -d db-dev-big /opt/mssql/bin/sqlservr
#docker run --name db-small -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Mission-123' -p 1433:1433 -d db-dev-small /opt/mssql/bin/sqlservr















