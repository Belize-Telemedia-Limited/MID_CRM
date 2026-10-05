using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{
    public partial class INVOICES
    {

        private INVOICESINVOICE[] iNVOICEField;

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("INVOICE")]
        public INVOICESINVOICE[] INVOICE
        {
            get
            {
                return this.iNVOICEField;
            }
            set
            {
                this.iNVOICEField = value;
            }
        }
    }

    public partial class INVOICESINVOICE
    {

        private uint idField;

        private uint iNVOICENUMBERField;

        private decimal pREVIOUSBILLAMOUNTField;

        private decimal pAIDAMOUNTField;

        private decimal cURRENTAMOUNTField;

        private decimal bILLAMOUNTField;

        private decimal rEMAINTOPAYField;        

        private uint iSSUEDATEField;

        private uint dUEDATEField;

        

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

    }



}