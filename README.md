#Notes for installing the WebApiCoreRegionMonitor 2.00
-----------------------------------------------------

The WebApiCoreRegionMonitor has the purpose of collecting visits on your OpenSim region. You can find the OpenSim part at 
the VallandShop (hop://hg.osgrid.org:80/ValLands/1180/815/52),
see http://www.vallands.ca for more information.

You need dotnet 8.0.31 to run the WebApiCoreRegionMonitor.

These steps assume you know what you are doing. As I can barely help you myself.
You must be the owner of your system, as you will need the root power.

This document show the installation on:

    -Linux  Ubuntu 22.04.2 LTS"

    -nginx/1.18.0 (Ubuntu) 

    -MySql Database  8.0.36-0ubuntu0.22.04.1

    -dotnet    8.0.31 [/usr/lib/dotnet/sdk]
    
It should be compatible for windows and probably MariaDB, although I haven’t tested it, and of course the installation will vary, in that case use these notes as a roughly guide.

Note that for these steps and further down the road, you really need to know what you are doing, 
and taking these steps I took here won’t necessarily mean success on your installation. 
as your installation might be slightly different than mine, 
however, I think that if I show you what I did, it might help you find what you need to do, adapting these instructions to your own environment. 
And I am not responsible in any way shape or form on whatever you do on your system. 
Take backups before proceeding.

if you never installed this package, proceed directly to step 1.



#Step 1: Get the package
------------------------
You will need the latest version of WebApiCoreRegionMonitor, you can get it here: https://github.com/valr300/WebApiCoreRegionMonitor 
You can get the folder "publish" only, the source isn’t needed.

Create folder /var/www/RentalApi on your linux Machine:

    sudo mkdir /var/www/RentalApi
    Put the content of the "publish" folder in /var/www/RegionMonitor :
cd {the place you put the package}
    
    sudo cp -r * /var/www/RegionMonitor


#Step 2: Create the Database
----------------------------
Execute the following script in your Database MySql 
you might get difficulties trying to execute all these from the command line, use the Workbench

    db_100.sql  		will build the database RegionMonitor, the Tables, views and procedure

you can use this script for queryying your data

    db_management.sql             This one show some example for querying the database


#Step 3: Create The user database for the Rental database
---------------------------------------------------------

execute the following lines.

    mysql -u root --password

(enter your mysql password, or if you haven't set password for MySQL server, type "mysql -u root" instead) 
You can even use MySQL Command Line Client on the Start menu on Windows. After login, create user, 
or if you prefer proceed to create you user via the Workbench, much easier!.

    CREATE USER 'YourDBUser'@'localhost' IDENTIFIED BY 'YOURPASSWORD';
    GRANT ALL PRIVILEGES ON YourDBUser.* TO 'RegionMonitor'@'localhost';


#Step 4: Add your API to Nginx
------------------------------
you will need to edit your sites-available/default and add the API.

    sudo vi /etc/nginx/sites-available/default 

add these line in the server{} definition ( the Http 80 section only will be enough, as the server will only be accessed locally, 
change YOURPORT by the Port number you want your service to run, usualy something like 5000, 5010, etc..
you will also want these port to be closed from outside, ie do not open them for the outside world, they will be access from localhost only)

       location /RM/ {
                    proxy_pass         http://localhost:YOURPORT;
                    proxy_http_version 1.1;
                    proxy_set_header   Upgrade $http_upgrade;
                    proxy_set_header   Connection keep-alive;
                    proxy_set_header   Host $host;
                    proxy_cache_bypass $http_upgrade;
                    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header   X-Forwarded-Proto $scheme;
         }
         
then enter the following command to tell Nginx the change

    sudo service nginx reload  
    
(at this point it would be wise to check if your web site is still working, make sure you didn’t cause any mess)

Note, there is no need to add this to your firewall, the adress will be use localy only.

#Step 5: Configuring the WebApiCoreRegionMonitor and first test
------------------------------------------------------------
edit connectionString in the /var/www/RegionMonitor/appsettings.json :

    cd /var/www/RentalApi
    sudo vi appsettings.json
    
edit as follow, replacing {YourUser} and {YourPassord} by the value created in 3:

    {
      "Logging": {
        "LogLevel": {
          "Default": "Information",
          "Microsoft.AspNetCore": "Warning"
        }
      },
      "AllowedHosts": "*",
       "ConnectionStrings": {
                   "RegionMonitor": "server=localhost;user={YourUser};database=RegionMonitor;port=3306;password={YourPassword};SslMode=none;"
                     }
    }

                     
then test the API, to see if it works (it should be waiting for request, press ctrl-c to exit) proceed to fix any error it could give you,
replace YOURPORT by the port you selected in step 4

    sudo /opt/dotnet/dotnet /var/www/RegionMonitor/WebApiCoreRegionMonitor.dll --urls http://localhost:YOURPORT
  
   
    
#Step 6: Configuring the Service
--------------------------------
You will create the following file to create your new service.

    sudo vi /etc/systemd/system/kestrel-WebApiCoreRegionMonitor.service 
and add the following lines (replacing the YOURPORT by the port number you want your service to run on):

    [Unit]
    Description=RentalApi
    
    [Service]
    WorkingDirectory=/var/www/RentalApi
    ExecStart=/opt/dotnet/dotnet /var/www/RegionMonitor/WebApiCoreRegionMonitor.dll --urls http://localhost:YOURPORT
    Restart=always
    # Restart service after 10 seconds if the dotnet service crashes:
    RestartSec=10
    KillSignal=SIGINT
    SyslogIdentifier=dotnet-example
    User=www-data
    Environment=ASPNETCORE_ENVIRONMENT=Production
    Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
    
    [Install]
    WantedBy=multi-user.target

    
#Step 7: Enabling the Service
-----------------------------
    sudo systemctl enable kestrel-WebApiCoreRental.service
    
#Step 8: Starting the Service
-----------------------------
    sudo systemctl stop kestrel-WebApiCoreRental.service 
    sudo systemctl start kestrel-WebApiCoreRental.service 
    
to check if it is running:

    sudo systemctl status kestrel-WebApiCoreRental.service 
    
proceed to fix any error it could give you, you can use the following command to help you find errors:

    journalctl -f
    sudo systemctl status nginx 
    
if it is not working, make sure you point to you right path for dotnet

#Step 9: Opening the port on your OpenSim installation
------------------------------------------------------
change the OpenSim.ini to allow the port connection (replacing the YOURPORT by the port number you want your service to run on):

OutboundDisallowForUserScriptsExcept = 127.0.0.1:YOURPORT
then restart your region

(if you already have address written there, simply add them with |    ex :  OutboundDisallowForUserScriptsExcept = 127.0.0.1:YOURPORT|ADDRESS2|Addres3 )

#Step 10: Tell the RegionMonitor Inworld your Server URL
--------------------------------------------------------
Inworld, edit the "!Config" notecard found in the "RegionMonitor"  prim content.
Set the :
IdSim=TheIdOfyourSim  # The same id you defined in your region file
UrlSendToApi=http://localhost:YOURPORT   # replace the "YOURPORT" by your port 


#Step 11: Testing
-----------------
Inworld, press the button "Test",
you will see the return message in the public chat, if everything work ok you should also see a new record in the table visits with the avatar Name "Valerie Test".
Just follow what the return message says if its not working.
When you are done with testing, you can delete the current test data from your workbench by issuing those query : (be careful, this will delete all data in the Visits tables)
delete from RegionMonitor.Visits_Zone;
delete from RegionMonitor.Visits ;


#Step 12: Queryiing your data
-----------------------------
The stats on MySql are populated on a few tables, you can query them from your Workbench or any other data tools,
here sre some quey you can use for querying

The Tables:

    Configs : Contain Your configuration ( timezone , nb Days for periodic stats, Include/exclude yourseff)
    ExcludedUsers : The AvatarName(s) you want to be excluded
    Regions :  Region monitored
    Visits : Contains all Visits
    Visits_Zone : Zone Visited

The views

    Visits_Detail : A detailed view of all visits 
    Visits_Dayly : your visitor for each days, duration time they came in and number of times
    Visits_NbrDayly : Number of visitors per day, unique visits and duration
    User_Detail : Each visits detailed
    Users_Stats_LastnDays : statistics for the last n days (see config)
    Users_Montly : montly statistic 
    
    
-- SETTINGS   Here you can say if you want to see yourself in the statistics or not
    
    -- set whether or not you want to see yourself reflected in stats
    update RegionMonitor.Configs set Value='1' where param='LISTOWNER';  -- List data including me
    update RegionMonitor.Configs set Value='0' where param='LISTOWNER'; -- List data excluding me
    -- stats per user :  Last n Days  (for exemple if you want to see the last 45 days instead, write 45
    update RegionMonitor.Configs set Value='30' where param='30DAYS';
    -- change / Set timezone
    update RegionMonitor.Configs set Value='-05.00' where param='TIMEZONE';


Querying the view:

    SELECT * FROM RegionMonitor.Regions;  -- to see your regions
    
    
    -- Stats Visits
    select * from RegionMonitor.Visits_Detail order by ArrivalTimeStamp desc;
    select * from RegionMonitor.Visits_Dayly;
    select * from RegionMonitor.Visits_NbrDayly order by Date desc;
    
    
    -- Stats Users 
    select * from RegionMonitor.Users_Detail where AvatarName like '%daddy kool%'
    select * from RegionMonitor.Users_Detail where ZoneVisiteds like '%Love Box%' order by ArrivalTimeStamp desc
    select * from RegionMonitor.Users_Montly order by Month desc;
    select * from RegionMonitor.Users_Stats_LastnDays;
    select * from RegionMonitor.Users_Stats_LastnDays order by NbrTime Desc, AvatarName, RegionName


Setps 13: All install now
-------------------------
If you have any questions, please join me either online or leave me a message on Element (https://matrix.to/#/#valr30room:matrix.org)
