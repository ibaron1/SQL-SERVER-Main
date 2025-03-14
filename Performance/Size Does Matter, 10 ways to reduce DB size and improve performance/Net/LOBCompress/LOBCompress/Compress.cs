/*************************************************************************************************
Dmitri Korotkevitch
http://aboutsqlserver.com
email: dmitri@aboutsqlserver.com

24HOP Russia (2015) - Size does Matter
CLR Functions to Compress and Decompress LOB Data
*************************************************************************************************/
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.IO;
using System.IO.Compression;
using System.Xml;
using Microsoft.SqlServer.Server;

public partial class Compress
{
    /// <summary>
    /// Compressing the data
    /// </summary>
    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true,
                                            DataAccess = DataAccessKind.None)]
    public static SqlBytes BinaryCompress(SqlBytes input)
    {
         if (input.IsNull)
             return SqlBytes.Null;

        using (MemoryStream result = new MemoryStream())
        {
            using (DeflateStream deflateStream = new DeflateStream(result, CompressionMode.Compress, true))
            {
                deflateStream.Write(input.Buffer, 0, input.Buffer.Length);
                deflateStream.Flush();
                deflateStream.Close();
            }
            return new SqlBytes(result.ToArray());
        } 
    }

    /// <summary>
    /// Decompressing the data
    /// </summary>
    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true,
                                            DataAccess = DataAccessKind.None)]
    public static SqlBytes BinaryDecompress(SqlBytes input)
    {
        if (input.IsNull)
            return SqlBytes.Null;

        int batchSize = 32768;
        byte[] buf = new byte[batchSize];

        using (MemoryStream result = new MemoryStream())
        {
            using (DeflateStream deflateStream = new DeflateStream(input.Stream, CompressionMode.Decompress, true))
            {
                int bytesRead;
                while ((bytesRead = deflateStream.Read(buf, 0, batchSize)) > 0)
                    result.Write(buf, 0, bytesRead);
            }
            return new SqlBytes(result.ToArray());
        } 
    }

    /// <summary>
    /// Demo function that illustrates the workaround of how to create persisted calculated coiumn that is used by SQL Server
    /// Uses bad code practices (After all, I am not .Net developer :) )
    /// </summary>
    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true,
                                            DataAccess = DataAccessKind.None)]
    public static SqlInt32 GetObjId(SqlBytes input)
    {
        if (input.IsNull)
            return SqlInt32.Null;

        int batchSize = 32768;
        byte[] buf = new byte[batchSize];

        using (MemoryStream result = new MemoryStream())
        {
            using (DeflateStream deflateStream = new DeflateStream(input.Stream, CompressionMode.Decompress, true))
            {
                int bytesRead;
                while ((bytesRead = deflateStream.Read(buf, 0, batchSize)) > 0)
                    result.Write(buf, 0, bytesRead);
            }
            result.Position = 0;
            using (XmlReader xml = XmlReader.Create(result))
            {
                while (xml.Read())
                {
                    if (xml.NodeType == XmlNodeType.Element && xml.Name == "row")
                    {
                        string obj = xml.GetAttribute("object_id");
                        int res;
                        if (String.IsNullOrEmpty(obj) || !Int32.TryParse(obj,out res))
                            return SqlInt32.Null;
                        
                        return new SqlInt32(res);
                    }
                }
                return SqlInt32.Null;
            }
        }
    }
}
