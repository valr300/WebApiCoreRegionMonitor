namespace WebApiCoreRegionMonitor
{
    public class RegionMonitor
    {

        public class Visit
        {
            public string Post { get; set; } = "";
            public string IdSim { get; set; } = "";
            public string IdAvatar { get; set; } = "";
            public string ArrivalTimeStamp { get; set; }
            public string DepartureTimeStamp { get; set; }
            public string AvatarName { get; set; } = "";
            public string AvatarGender { get; set; } = "";
            public string AvatarGroup { get; set; } = "";
            public string ArrivalPos { get; set; } = "";
            public string LastPos { get; set; } = "";
            public string AvatarLastGroup { get; set; } = "";
            public int TimeSpentSeconds { get; set; }
            public string ZonesVisited { get; set; } = "";
            public int IsNPC { get; set; }
        }

    }
}
