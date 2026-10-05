using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{
    /*public class Topup
    {
    }*/

    public partial class TOPUPS
    {

        private TOPUPTOPUP[] tOPUPField;

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("TOPUP")]
        public TOPUPTOPUP[] TOPUP
        {
            get
            {
                return this.tOPUPField;
            }
            set
            {
                this.tOPUPField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    public partial class TOPUPTOPUP
    {

        private uint tOPUPIDField;

        private decimal tOPUPAMOUNTField;

        private string tOPUPDATEField;

        /// <remarks/>
        public uint TOPUPID
        {
            get
            {
                return this.tOPUPIDField;
            }
            set
            {
                this.tOPUPIDField = value;
            }
        }

        /// <remarks/>
        public decimal TOPUPAMOUNT
        {
            get
            {
                return this.tOPUPAMOUNTField;
            }
            set
            {
                this.tOPUPAMOUNTField = value;
            }
        }

        /// <remarks/>
        public string TOPUPDATE
        {
            get
            {
                return this.tOPUPDATEField;
            }
            set
            {
                this.tOPUPDATEField = value;
            }
        }
    }

}