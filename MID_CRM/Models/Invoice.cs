using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{
    /*public class Invoice
    {
    }*/


    // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
    /// <remarks/>
   /* [System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    [System.Xml.Serialization.XmlRootAttribute(IsNullable = false)]
    public partial class INVOICE
    {

        private uint iNVOICENUMBERField;

        private decimal pREVIOUSBILLAMOUNTField;

        private decimal pAIDAMOUNTField;

        private decimal cURRENTAMOUNTField;

        private decimal bILLAMOUNTField;

        private decimal rEMAINTOPAYField;

        private uint iSSUEDATEField;

        private uint dUEDATEField;

        private uint idField;

        /// <remarks/>
        public uint INVOICENUMBER
        {
            get
            {
                return this.iNVOICENUMBERField;
            }
            set
            {
                this.iNVOICENUMBERField = value;
            }
        }

        /// <remarks/>
        public decimal PREVIOUSBILLAMOUNT
        {
            get
            {
                return this.pREVIOUSBILLAMOUNTField;
            }
            set
            {
                this.pREVIOUSBILLAMOUNTField = value;
            }
        }

        /// <remarks/>
        public decimal PAIDAMOUNT
        {
            get
            {
                return this.pAIDAMOUNTField;
            }
            set
            {
                this.pAIDAMOUNTField = value;
            }
        }

        /// <remarks/>
        public decimal CURRENTAMOUNT
        {
            get
            {
                return this.cURRENTAMOUNTField;
            }
            set
            {
                this.cURRENTAMOUNTField = value;
            }
        }

        /// <remarks/>
        public decimal BILLAMOUNT
        {
            get
            {
                return this.bILLAMOUNTField;
            }
            set
            {
                this.bILLAMOUNTField = value;
            }
        }

        /// <remarks/>
        public decimal REMAINTOPAY
        {
            get
            {
                return this.rEMAINTOPAYField;
            }
            set
            {
                this.rEMAINTOPAYField = value;
            }
        }

        /// <remarks/>
        public uint ISSUEDATE
        {
            get
            {
                return this.iSSUEDATEField;
            }
            set
            {
                this.iSSUEDATEField = value;
            }
        }

        /// <remarks/>
        public uint DUEDATE
        {
            get
            {
                return this.dUEDATEField;
            }
            set
            {
                this.dUEDATEField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public uint ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }
    }


}