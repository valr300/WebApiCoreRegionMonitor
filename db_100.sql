CREATE DATABASE `RegionMonitor` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;


CREATE TABLE `Configs` (
  `param` varchar(36) NOT NULL,
  `description` varchar(90) DEFAULT NULL,
  `Value` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`param`),
  UNIQUE KEY `IdVisit_UNIQUE` (`param`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `Regions` (
  `idRegion` char(38) NOT NULL,
  `RegionName` varchar(65) DEFAULT NULL,
  PRIMARY KEY (`idRegion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `Visits` (
  `IdVisit` varchar(36) NOT NULL,
  `IdRegion` varchar(36) DEFAULT NULL,
  `ArrivalTimeStamp` datetime DEFAULT NULL,
  `IdAvatar` varchar(36) DEFAULT NULL,
  `DepartureTimeStamp` datetime DEFAULT NULL,
  `AvatarName` varchar(255) DEFAULT NULL,
  `AvatarGender` varchar(20) DEFAULT NULL,
  `AvatarGroup` varchar(255) DEFAULT NULL,
  `ArrivalPos` varchar(120) DEFAULT NULL,
  `LastPos` varchar(120) DEFAULT NULL,
  `AvatarLastGroup` varchar(255) DEFAULT NULL,
  `TimeSpentSeconds` int DEFAULT NULL,
  `IsNPC` int DEFAULT NULL,
  PRIMARY KEY (`IdVisit`),
  UNIQUE KEY `IdVisit_UNIQUE` (`IdVisit`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `Visits_Zone` (
  `IdVisit` varchar(36) NOT NULL,
  `ZoneVisited` varchar(65) NOT NULL,
  PRIMARY KEY (`IdVisit`,`ZoneVisited`),
  CONSTRAINT `Visits_Zone_ibfk_1` FOREIGN KEY (`IdVisit`) REFERENCES `Visits` (`IdVisit`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `RegionMonitor`.`ExcludedUsers` (
  `AvatarName` NVARCHAR(127) NOT NULL,
  PRIMARY KEY (`AvatarName`));



DELIMITER $$
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
			) VALUES (IdVisit, IdRegion,ArrivalTimeStamp, IdAvatar, DepartureTimeStamp,
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

   end if;
  
END$$
DELIMITER ;



-- initialising configuration
insert ExcludedUsers select 'YourAvatarName';  -- do this for all other avatar you want to exclude from stats data
insert RegionMonitor.Configs select 'LISTOWNER',	'Display owner(s)', '0';
insert RegionMonitor.Configs select '30DAYS',       'Statistique users - Nbr last Days',	'30';
insert RegionMonitor.Configs select 'TIMEZONE',     'YourTimezoneHours',	'-05:00';  -- replace  with your timezone diff ex  '+00.01'




USE `RegionMonitor`;
CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `ZoneVisiteds` AS
    SELECT  
        `vz`.`IdVisit` AS `IdVisit`,
        GROUP_CONCAT(`vz`.`ZoneVisited`           SEPARATOR ', ') AS `ZoneVisiteds`
    FROM
        `Visits_Zone` `vz`
    GROUP BY `vz`.`IdVisit`;




USE `RegionMonitor`;
CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `Visits_Detail` AS
    SELECT 
        CONVERT_TZ(`v`.`ArrivalTimeStamp`,
                '+00:00',
                `ctz`.`Value`) AS `ArrivalTimeStamp`,
        CONVERT_TZ(`v`.`DepartureTimeStamp`,
                '+00:00',
                `ctz`.`Value`) AS `DepartureTimeStamp`,
        `v`.`AvatarName` AS `AvatarName`,
        `r`.`RegionName` AS `RegionName`,
        `RegionMonitor`.`FmtTimeDuration`(`v`.`TimeSpentSeconds`) AS `Duration`,
        `v`.`AvatarGender` AS `AvatarGender`,
        `v`.`AvatarGroup` AS `AvatarGroup`,
        `zv`.`ZoneVisiteds` AS `ZoneVisiteds`,
        `v`.`ArrivalPos` AS `ArrivalPos`,
        `v`.`LastPos` AS `LastPos`,
        `v`.`AvatarLastGroup` AS `AvatarLastGroup`,
        `v`.`IsNPC` AS `IsNPC`,
        `v`.`IdVisit` AS `IdVisit`,
        `v`.`IdAvatar` AS `IdAvatar`
    FROM
        ((((`Visits` `v`
        JOIN `Regions` `r` ON ((`r`.`idRegion` = `v`.`IdRegion`)))
        JOIN `Configs` `clo` ON ((`clo`.`param` = 'LISTOWNER')))
        JOIN `Configs` `ctz` ON ((`ctz`.`param` = 'TIMEZONE')))
        LEFT JOIN `ZoneVisiteds` `zv` ON ((`zv`.`IdVisit` = `v`.`IdVisit`)))
    WHERE
        (
          (  (`clo`.`Value` = '0')         AND EXISTS( SELECT   `ExcludedUsers`.`AvatarName`  FROM `ExcludedUsers`   WHERE  (`ExcludedUsers`.`AvatarName` = `v`.`AvatarName`))   IS  FALSE       )          
              OR (`clo`.`Value` <> '0')
         )
    ORDER BY `v`.`ArrivalTimeStamp` DESC;



USE `RegionMonitor`;
CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `Visits_NbrDayly` AS
    SELECT 
        `r`.`RegionName` AS `RegionName`,
        CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,  '+00:00',   `ctz`.`Value`) 
            AS DATE) AS `Date`,
        COUNT(0) AS `NbrVisits`,
        COUNT(DISTINCT `v`.`IdAvatar`) AS `NbrUniqueVisitor`,
        `RegionMonitor`.`FmtTimeDuration`(SUM(`v`.`TimeSpentSeconds`)) AS `Duration`,
        SUM(`v`.`TimeSpentSeconds`) AS `Seconds`,
        (SUM(`v`.`TimeSpentSeconds`) / 60) AS `minutes`,
        ((SUM(`v`.`TimeSpentSeconds`) / 60) / 60) AS `hours`
    FROM
        `Visits` `v`
        JOIN `Regions` `r` ON ((`r`.`idRegion` = `v`.`IdRegion`))
        JOIN `Configs` `clo` ON ((`clo`.`param` = 'LISTOWNER'))
        JOIN `Configs` `ctz` ON ((`ctz`.`param` = 'TIMEZONE'))
    WHERE
        (((`clo`.`Value` = '0') AND EXISTS( SELECT  `ExcludedUsers`.`AvatarName`  FROM `ExcludedUsers`  WHERE  (`ExcludedUsers`.`AvatarName` = `v`.`AvatarName`))    IS FALSE)   OR (`clo`.`Value` <> '0'))
    GROUP BY `r`.`RegionName` , CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`, '+00:00',  `ctz`.`Value`)     AS DATE)
    ORDER BY `r`.`RegionName` , CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`, '+00:00',  `ctz`.`Value`)     AS DATE) DESC;



USE `RegionMonitor`;
CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `Visits_Dayly` AS
    SELECT 
        `r`.`RegionName` AS `RegionName`,
        CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,
                    '+00:00',
                    ctz.Value)
            AS DATE) AS `Date`,
        COUNT(0) AS `NbrTime`,
        `RegionMonitor`.`FmtTimeDuration`(SUM(`v`.`TimeSpentSeconds`)) AS `Duration`,
        `v`.`AvatarName` AS `AvatarName`,
        `v`.`AvatarGender` AS `AvatarGender`,
        SUM(`v`.`TimeSpentSeconds`) AS `Seconds`,
        (SUM(`v`.`TimeSpentSeconds`) / 60) AS `minutes`,
        ((SUM(`v`.`TimeSpentSeconds`) / 60) / 60) AS `hours` 
    FROM
        
        `Visits` `v`
        JOIN `Regions` `r` ON ((`r`.`idRegion` = `v`.`IdRegion`))
        JOIN `Configs` `clo` ON ((`clo`.`param` = 'LISTOWNER'))
        JOIN `Configs` `ctz` ON ((`ctz`.`param` = 'TIMEZONE')) 
        
	WHERE
        (
          ((`clo`.`Value` = '0')   AND EXISTS( SELECT  `ExcludedUsers`.`AvatarName`  FROM `ExcludedUsers`   WHERE (`ExcludedUsers`.`AvatarName` = `v`.`AvatarName`))   IS FALSE)
           OR (`clo`.`Value` <> '0')
         )
    GROUP BY `r`.`RegionName` , `v`.`AvatarName` , `v`.`AvatarGender` , CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,
                '+00:00',
                ctz.Value)
        AS DATE)
    ORDER BY `r`.`RegionName` , CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,
                '+00:00',
                ctz.Value)
        AS DATE) DESC , `v`.`AvatarName`;




USE `RegionMonitor`;
CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `Users_Detail` AS
    SELECT 
        `Visits_Detail`.`AvatarName` AS `AvatarName`, 
        `Visits_Detail`.`RegionName` AS `RegionName`,
        `Visits_Detail`.`ArrivalTimeStamp` AS `ArrivalTimeStamp`,
        `Visits_Detail`.`DepartureTimeStamp` AS `DepartureTimeStamp`,
        `Visits_Detail`.`Duration` AS `Duration`,
        `Visits_Detail`.`AvatarGender` AS `AvatarGender`,
        `Visits_Detail`.`AvatarGroup` AS `AvatarGroup`,
        `Visits_Detail`.`ZoneVisiteds` AS `ZoneVisiteds`,
        `Visits_Detail`.`ArrivalPos` AS `ArrivalPos`,
        `Visits_Detail`.`LastPos` AS `LastPos`,
        `Visits_Detail`.`AvatarLastGroup` AS `AvatarLastGroup`,
        `Visits_Detail`.`IsNPC` AS `IsNPC`,
        `Visits_Detail`.`IdVisit` AS `IdVisit`
    FROM
        `Visits_Detail`
    ORDER BY `Visits_Detail`.`AvatarName` , `Visits_Detail`.`ArrivalTimeStamp` , `Visits_Detail`.`RegionName`;



 USE `RegionMonitor`;
CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `Users_Stats_LastnDays` AS
    SELECT 
        `v`.`AvatarName` AS `AvatarName`,
        `r`.`RegionName` AS `RegionName`,
        COUNT(0) AS `NbrTime`,
        `RegionMonitor`.`FmtTimeDuration`(SUM(`v`.`TimeSpentSeconds`)) AS `Duration`,
        `v`.`AvatarGender` AS `AvatarGender`,
        SUM(`v`.`TimeSpentSeconds`) AS `Seconds`,
        (SUM(`v`.`TimeSpentSeconds`) / 60) AS `minutes`,
        ((SUM(`v`.`TimeSpentSeconds`) / 60) / 60) AS `hours` 
    FROM
        `Visits` `v`
        JOIN `Regions` `r` ON ((`r`.`idRegion` = `v`.`IdRegion`))
        JOIN `Configs` `clo` ON ((`clo`.`param` = 'LISTOWNER'))
        JOIN `Configs` `ctz` ON ((`ctz`.`param` = 'TIMEZONE'))
        JOIN `Configs` `c30` ON ((`c30`.`param` = '30DAYS'))
    WHERE
        (
           (
            ((`clo`.`Value` = '0')   AND EXISTS( SELECT  `ExcludedUsers`.`AvatarName`  FROM `ExcludedUsers`   WHERE (`ExcludedUsers`.`AvatarName` = `v`.`AvatarName`))   IS FALSE)
             OR (`clo`.`Value` <> '0')
           )
        AND (CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,      '+00:00',  ctz.Value)     AS DATE) >= (CURDATE() - INTERVAL `c30`.`Value` DAY)))
    GROUP BY `r`.`RegionName` , `v`.`AvatarName` , `v`.`AvatarGender`
    ORDER BY `v`.`AvatarName` , `r`.`RegionName`;



USE `RegionMonitor`;
CREATE 
     OR REPLACE ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `Users_Montly` AS
    SELECT 
        `v`.`AvatarName` AS `AvatarName`,
        CAST(CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,
                        '+00:00',
                        `ctz`.`Value`)
                AS DATE)
            AS CHAR (7) CHARSET UTF8MB4) AS `Month`,
        `r`.`RegionName` AS `RegionName`,
        COUNT(0) AS `NbrTime`, 
        `RegionMonitor`.`FmtTimeDuration`(SUM(`v`.`TimeSpentSeconds`)) AS `Duration`,
        `v`.`AvatarGender` AS `AvatarGender`,
        SUM(`v`.`TimeSpentSeconds`) AS `Seconds`,
        (SUM(`v`.`TimeSpentSeconds`) / 60) AS `minutes`,
        ((SUM(`v`.`TimeSpentSeconds`) / 60) / 60) AS `hours`
    FROM
        (((`Visits` `v`
        JOIN `Regions` `r` ON ((`r`.`idRegion` = `v`.`IdRegion`)))
        JOIN `Configs` `clo` ON ((`clo`.`param` = 'LISTOWNER')))
        JOIN `Configs` `ctz` ON ((`ctz`.`param` = 'TIMEZONE')))
    WHERE
        (((`clo`.`Value` = '0')
            AND EXISTS( SELECT 
                `ExcludedUsers`.`AvatarName`
            FROM
                `ExcludedUsers`
            WHERE
                (`ExcludedUsers`.`AvatarName` = `v`.`AvatarName`))
            IS FALSE)
            OR (`clo`.`Value` <> '0'))
    GROUP BY `r`.`RegionName` , `v`.`AvatarName` , `v`.`AvatarGender` , CAST(CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,
                    '+00:00',
                    `ctz`.`Value`)
            AS DATE)
        AS CHAR (7) CHARSET UTF8MB4)
    ORDER BY `v`.`AvatarName` , CAST(CAST(CONVERT_TZ(`v`.`ArrivalTimeStamp`,
                    '+00:00',
                    `ctz`.`Value`)
            AS DATE)
        AS CHAR (7) CHARSET UTF8MB4) DESC , `r`.`RegionName`;





