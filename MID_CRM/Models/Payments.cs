using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{

    // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]*/
    public partial class PAYMENTS
    {

        private PAYMENTSPAYMENT[] pAYMENTField;

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("PAYMENT")]
        public PAYMENTSPAYMENT[] PAYMENT
        {
            get
            {
                return this.pAYMENTField;
            }
            set
            {
                this.pAYMENTField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    public partial class PAYMENTSPAYMENT
    {

        private uint pAYMENTIDField;

        private decimal pAYMENTAMOUNTField;

        private uint pAYMENTDATEField;

        /// <remarks/>
        public uint PAYMENTID
        {
            get
            {
                return this.pAYMENTIDField;
            }
            set
            {
                this.pAYMENTIDField = value;
            }
        }

        /// <remarks/>
        public decimal PAYMENTAMOUNT
        {
            get
            {
                return this.pAYMENTAMOUNTField;
            }
            set
            {
                this.pAYMENTAMOUNTField = value;
            }
        }

        /// <remarks/>
        public uint PAYMENTDATE
        {
            get
            {
                return this.pAYMENTDATEField;
            }
            set
            {
                this.pAYMENTDATEField = value;
            }
        }
    }


}