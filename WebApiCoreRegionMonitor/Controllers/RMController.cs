﻿using System;
using System.Configuration;
using System.Diagnostics;
using Google.Protobuf;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Formatters;
using Microsoft.Extensions.Configuration;
using MySql.Data.MySqlClient;
using MySqlX.XDevAPI.Relational;
using static WebApiCoreRegionMonitor.RegionMonitor;

namespace WebApiCoreRegionMonitor.Controllers
{
    [ApiController]
    [Route("[controller]")]

    public class RMController : Controller
    {
        // requires using Microsoft.Extensions.Configuration;
        private readonly IConfiguration _configuration;

        public RMController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpPost(Name = "AddVisit")]
        // POST: api/RM
        //   [ResponseType(typeof(string))]
        public string AddVisit(RegionMonitor.Visit aVisit)
        {
            int rows = -1;
            string trace = "";
            string sp = aVisit.Post;
            string Response= "";

            try
            {
                string connStr = _configuration.GetSection("ConnectionStrings").GetSection("RegionMonitor").Value;

                if ( !(sp == "AddVisitor" || sp == "SendLastRows" ))
                    return "";

                //receive key7ba0a504-dcf1 - 4922 - b46d - d22b30610ec9,status = 400 meta = body ={
                //"type":"https://tools.ietf.org/html/rfc9110#section-15.5.1",
                //"title":"One or more validation errors occurred.",
                //"status":400,"errors":
                //{ "aVisit":["The aVisit field is required."],
                //"$.DepartureTimeStamp":["The JSON value could not be converted to System.DateTime.
                //Path: $.DepartureTimeStamp | LineNumber: 0 | BytePositionInLine: 189."]},
                //"traceId":"00-6a717f269e947d6f611c1035c40641de-4ccffb65c402ee24-00"}



                MySqlConnection conn = new MySqlConnection(connStr);
                MySqlCommand cmd = new MySqlCommand(sp, conn);
                cmd.CommandType = System.Data.CommandType.StoredProcedure;






                if (sp == "AddVisitor")
                {
                    DateTime ArrivalTimeStamp = DateTime.Now;  // variable declaration
                    DateTime DepartureTimeStamp = DateTime.Now;  // variable declaration
                    if (!string.IsNullOrWhiteSpace(aVisit.ArrivalTimeStamp))
                        ArrivalTimeStamp = DateTime.Parse(aVisit.ArrivalTimeStamp);


                    if (!string.IsNullOrWhiteSpace(aVisit.DepartureTimeStamp))
                        DepartureTimeStamp = DateTime.Parse(aVisit.DepartureTimeStamp);

                    cmd.Parameters.AddWithValue("@IdRegion", aVisit.IdSim);
                    cmd.Parameters.AddWithValue("@ArrivalTimeStamp", ArrivalTimeStamp);
                    cmd.Parameters.AddWithValue("@IdAvatar", aVisit.IdAvatar);
                    
                    cmd.Parameters.AddWithValue("@DepartureTimeStamp", DepartureTimeStamp);
                    cmd.Parameters.AddWithValue("@AvatarName", aVisit.AvatarName);
                    cmd.Parameters.AddWithValue("@AvatarGender", aVisit.AvatarGender);
                    cmd.Parameters.AddWithValue("@AvatarGroup", aVisit.AvatarGroup);
                    cmd.Parameters.AddWithValue("@ArrivalPos", aVisit.ArrivalPos);
                    cmd.Parameters.AddWithValue("@LastPos", aVisit.LastPos);
                    cmd.Parameters.AddWithValue("@AvatarLastGroup", aVisit.AvatarLastGroup);
                    cmd.Parameters.AddWithValue("@TimeSpentSeconds", aVisit.TimeSpentSeconds);
                    cmd.Parameters.AddWithValue("@ZonesVisited", aVisit.ZonesVisited);
                    cmd.Parameters.AddWithValue("@IsNPC", aVisit.IsNPC);
                    trace += "\n4";
                    conn.Open();

                    rows = cmd.ExecuteNonQuery();
                    conn.Close();
                    Response = rows.ToString();
                }
                if (sp == "SendLastRows")
                {
               
                    cmd.Parameters.AddWithValue("@IdRegion", aVisit.IdSim);
                    cmd.Parameters.AddWithValue("@NumberRows", aVisit.NumberRows);
                    trace += "\n4";
                    conn.Open();

                  //  rows = cmd.ExecuteReader();
                    MySqlDataReader reader = cmd.ExecuteReader();
                    while (reader.Read())
                    {
                        Response+= "\n"+String.Format("{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|{8}|{9}|{10}|{11}|{12}|{13}", 
                            reader[0], reader[1], reader[2], reader[3], reader[4], reader[5], reader[6],
                            reader[7], reader[8], reader[9], reader[10], reader[11], reader[12], reader[13]);
                    }

                    conn.Close();
                    
                }
            }
            catch (Exception ex)
            {
                return string.Format("Exception = " + ex.Message + " \n" + trace + "\n" + ex.ToString(), rows);

            }

            return Response;
        }
    }
}
