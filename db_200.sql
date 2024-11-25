USE `RegionMonitor`;
DROP procedure IF EXISTS `SendLastRows`;

USE `RegionMonitor`;
DROP procedure IF EXISTS `RegionMonitor`.`SendLastRows`;
;

DELIMITER $$
USE `RegionMonitor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `SendLastRows`( IdRegion varchar(36),
  NumberRows integer 
 )
BEGIN 

select  v.IdAvatar , v.ArrivalTimeStamp, v.DepartureTimeStamp,
			v.AvatarName, v.AvatarGender, v.AvatarGroup, v.ArrivalPos, 
            v.DepartureTimeStamp, v.LastPos, v.AvatarLastGroup, v.TimeSpentSeconds, 
			 vz.ZoneVisiteds, v.IsNPC,  v.IdVisit
  from  Visits v       
  left join ZoneVisiteds vz  on (vz.IdVisit=v.IdVisit)
  order by v.ArrivalTimeStamp desc
  limit NumberRows;
  
END$$

DELIMITER ;
;



USE `RegionMonitor`;
DROP procedure IF EXISTS `AddVisitor`;

USE `RegionMonitor`;
DROP procedure IF EXISTS `RegionMonitor`.`AddVisitor`;
;

DELIMITER $$
USE `RegionMonitor`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddVisitor`(

  IdRegion varchar(36),
  ArrivalTimeStamp datetime,  
  IdAvatar varchar(36),
  DepartureTimeStamp datetime,
  AvatarName varchar(255),
  AvatarGender varchar(20),
  AvatarGroup varchar(255),
  ArrivalPos varchar(120),
  LastPos varchar(120),
  AvatarLastGroup varchar(255),
  TimeSpentSeconds int,
  ZonesVisited varchar(255),
  IsNPC int
  )
BEGIN
  declare IdVisit VARCHAR(36);
  declare TestTmp varchar(255);
  declare dest varchar(65);
  declare posv integer;

  set IdVisit = uuid();       
   if not exists(Select * from RegionMonitor.Visits as v
	 		where v.IdRegion = IdRegion and v.ArrivalTimeStamp = ArrivalTimeStamp and v.IdAvatar=IdAvatar) then
        
	  INSERT INTO RegionMonitor.Visits ( IdVisit, IdRegion, ArrivalTimeStamp, IdAvatar, DepartureTimeStamp,
			AvatarName, AvatarGender, AvatarGroup, ArrivalPos, LastPos, AvatarLastGroup, TimeSpentSeconds, 
			IsNPC 
			) VALUES (IdVisit, IdRegion,ArrivalTimeStamp, IdAvatar, IFNULL(DepartureTimeStamp,ArrivalTimeStamp),
			AvatarName, AvatarGender, AvatarGroup, ArrivalPos, LastPos, AvatarLastGroup, TimeSpentSeconds, 
			IsNPC );
			
		set testtmp=ZonesVisited;
		repeat
		  set posv =  instr(testtmp,',');

		  if posv >0 then 
			 set dest =  substring(testtmp, 1, posv-1);
			 set testtmp = substring(testtmp, posv+1);
		   else
			  set dest = testtmp;
			  set testtmp=''; 
		   end if;    
		   if dest != '' then
		   insert into RegionMonitor.Visits_Zone (IdVisit, ZoneVisited)
					values(IdVisit, dest);
		   end if;         
		until testtmp = '' 
		end repeat;
        else
        begin
          
           select  v.IdVisit into @IdVisit
            from RegionMonitor.Visits as v
	 	 	where v.IdRegion = IdRegion and v.ArrivalTimeStamp = ArrivalTimeStamp and v.IdAvatar=IdAvatar
            limit 1;
             
        
          update  RegionMonitor.Visits as v set
            v.DepartureTimeStamp  =IFNULL(DepartureTimeStamp,ArrivalTimeStamp),
			v.AvatarName = AvatarName, v.AvatarGender  =AvatarGender, v.AvatarGroup =AvatarGroup, v.ArrivalPos= ArrivalPos, 
            v.LastPos=LastPos, v.AvatarLastGroup=AvatarLastGroup, v.TimeSpentSeconds=TimeSpentSeconds, 
			IsNPC =IsNPC
          where  v.IdVisit = @IdVisit;
            
          delete from RegionMonitor.Visits_Zone as vz  where vz.IdVisit=@IdVisit; 
            
        set @testtmp=ZonesVisited;
		repeat
		  set @posv =  instr(@testtmp,',');

		  if @posv >0 then 
			 set @dest =  substring(@testtmp, 1, @posv-1);
			 set @testtmp = substring(@testtmp, @posv+1);
		   else
			  set @dest = @testtmp;
			  set @testtmp=''; 
		   end if;    
		   if @dest != '' then
		   insert into RegionMonitor.Visits_Zone (IdVisit, ZoneVisited)
					values(@IdVisit, @dest);
		   end if;         
	   	 until @testtmp = '' 
		end repeat;          
        end; 

   end if;
  
END$$

DELIMITER ;
;

