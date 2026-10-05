using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{
    public class UpdateAccount
    {
        public string VI_USERNAME { get; set; }
        public string VI_PASSWORD { get; set; }
        //public string VI_PHONENUMBER { get; set; }
        public string VI_ACCOUNT_CODE { get; set; }
        public int VI_CONTACT_ID { get; set; }
        public int VI_SUBSCRIBER_SESSION_ID { get; set; }
        //public string VI_NEWPHONENUMBER { get; set; }
        public string VI_PHONENUMBER { get; set; }
        public string VI_FIRSTNAME { get; set; }
        public string VI_MIDDLENAME { get; set; }
        public string VI_LASTNAME { get; set; }
        public string VI_DOB { get; set; }
        public string VI_EMAIL { get; set; }
    }
}