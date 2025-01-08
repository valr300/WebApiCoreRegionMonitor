 ﻿-- to add Region :
insert RegionMonitor.Regions select 'uuid of your region', 'Name of your region';


-- general purpose querying
-- here's some ways of querying your visitors

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


-- Here you can say if you want to see yourself in the statistics or not
-- ------------
-- SETTINGS  --
-- ------------

-- set whether or not you want to see yourself reflected in stats
update RegionMonitor.Configs set Value='1' where param='LISTOWNER';  -- List data including me
update RegionMonitor.Configs set Value='0' where param='LISTOWNER'; -- List data excluding me
-- stats per user :  Last n Days  (for exemple if you want to see the last 45 days instead, write 45
update RegionMonitor.Configs set Value='30' where param='30DAYS';
-- change / Set timezone
update RegionMonitor.Configs set Value='-05.00' where param='TIMEZONE'; -- set your time zone, so data get listed with your current time zone


--Adding the Avatarname you dont want listed  in the views (LISTOWNER, typicalyy that would be your AvatarName, and or maybe your staff)
select * from ExcludedUsers;   -- see whose is excluded
insert ExcludedUsers select "Test";       -- replace avatarname by the Avatarname you dont want listed, do as many as you want, one by one
delete from ExcludedUsers where AvatarName="Test";   -- if you ever want to remove one from the list


