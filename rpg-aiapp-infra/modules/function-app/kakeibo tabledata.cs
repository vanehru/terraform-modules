using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AzureOpenAISample
{
    [JsonObject]
    public class KakeiboTableList
    {
        [JsonProperty("List")]
        public List<KakeiboTableRow> List { get; set; } = new List<KakeiboTableRow>();
    }

    [JsonObject]
    public class KakeiboTableRow
    {

        [JsonProperty("Date")]
        public DateTime Date { get; set; }

        [JsonProperty("Inout")]
        public string Inout { get; set; }

        [JsonProperty("Category")]
        public string Category { get; set; }

        [JsonProperty("Amount")]
        public int Amount { get; set; }

    }

    [JsonObject]
    public class PlayerDataList
    {
        [JsonProperty("PlayerDataList")]
        public List<PlayerDataRow> List { get; set; } = new List<PlayerDataRow>();
    }

    [JsonObject]
    public class PlayerDataRow
    {
        [JsonProperty("UserId")]
        public string UserId { get; set; } 

        [JsonProperty("CharId")]
        public int CharId { get; set; }

        [JsonProperty("Exp")]
        public int Exp { get; set; }

        [JsonProperty("Parameter1")]
        public int Parameter1 { get; set; }

        [JsonProperty("Parameter2")]
        public int Parameter2 { get; set; }

        [JsonProperty("Parameter3")]
        public int Parameter3 { get; set; }

        [JsonProperty("Parameter4")]
        public int Parameter4 { get; set; }

        [JsonProperty("CurrentEventId")]
        public int CurrentEventId { get; set; } 

        [JsonProperty("CurrentSeq")]
        public int CurrentSeq { get; set; }
    }

}