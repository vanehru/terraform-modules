using Newtonsoft.Json;
using System.Collections.Generic;

namespace ORC_APP
{
    [JsonObject]
    public class BusinessCardList
    {
        [JsonProperty("cards")]
        public List<BusinessCard> Cards { get; set; } = new List<BusinessCard>();
    }

    [JsonObject]
    public class BusinessCard
    {
        [JsonProperty("firstName")]
        public string FirstName { get; set; }

        [JsonProperty("lastName")]
        public string LastName { get; set; }

        [JsonProperty("companyNames")]
        public List<string> CompanyNames { get; set; } = new List<string>();

        [JsonProperty("emails")]
        public List<string> Emails { get; set; } = new List<string>();

        [JsonProperty("mobilePhones")]
        public List<string> MobilePhones { get; set; } = new List<string>();

        [JsonProperty("addresses")]
        public List<string> Addresses { get; set; } = new List<string>();

        [JsonProperty("jobTitles")]
        public List<string> JobTitles { get; set; } = new List<string>();

        [JsonProperty("departments")]
        public List<string> Departments { get; set; } = new List<string>();

        [JsonProperty("workPhones")]
        public List<string> WorkPhones { get; set; } = new List<string>();

        [JsonProperty("websites")]
        public List<string> Websites { get; set; } = new List<string>();
    }
}
