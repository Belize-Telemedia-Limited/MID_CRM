using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{
       // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
    /// <remarks/>
   /* [System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    [System.Xml.Serialization.XmlRootAttribute(IsNullable = false)]
    public partial class ACCOUNT
    {

        //private ulong cODEField;

        private string cODEField;

        private string nAMEField;

        private string pRODUCTField;

        private string sTATUSField;

        //private decimal bALANCEField;
        private decimal? bALANCEField;

        private string cREDIT_LIMITField;

        private string bILL_CYCLEField;

        private string iNVOICE_SHIP_PRESENTATIONField;

        private ACCOUNTCONTACT[] cONTACT_LISTField;

        /// <remarks/>
        public string CODE
        {
            get
            {
                return this.cODEField;
            }
            set
            {
                this.cODEField = value;
            }
        }

        /// <remarks/>
        public string NAME
        {
            get
            {
                return this.nAMEField;
            }
            set
            {
                this.nAMEField = value;
            }
        }

        /// <remarks/>
        public string PRODUCT
        {
            get
            {
                return this.pRODUCTField;
            }
            set
            {
                this.pRODUCTField = value;
            }
        }

        public string STATUS
        {
            get
            {
                return this.sTATUSField;
            }
            set
            {
                this.sTATUSField = value;
            }
        }

        public decimal? BALANCE
        {
            get
            {
                return this.bALANCEField;
            }
            set
            {
                this.bALANCEField = value;
            }
        }

        /// <remarks/>
        public string CREDIT_LIMIT
        {
            get
            {
                return this.cREDIT_LIMITField;
            }
            set
            {
                this.cREDIT_LIMITField = value;
            }
        }

        /// <remarks/>
        public string BILL_CYCLE
        {
            get
            {
                return this.bILL_CYCLEField;
            }
            set
            {
                this.bILL_CYCLEField = value;
            }
        }

        /// <remarks/>
        public string INVOICE_SHIP_PRESENTATION
        {
            get
            {
                return this.iNVOICE_SHIP_PRESENTATIONField;
            }
            set
            {
                this.iNVOICE_SHIP_PRESENTATIONField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("CONTACT", IsNullable = false)]
        public ACCOUNTCONTACT[] CONTACT_LIST
        {
            get
            {
                return this.cONTACT_LISTField;
            }
            set
            {
                this.cONTACT_LISTField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    public partial class ACCOUNTCONTACT
    {

        private int idField;

        private string pRIMARYField;

        private string sHIPMENTField;

        private string fIRSTNAMEField;

        private string mIDDLENAMEField;

        private string lASTNAMEField;

        private string cOMPANYNAMEField;

        //private System.DateTime dOBField;
        private string dOBField;


        private string sTREETField;

        private string cITYField;

        private string sTATEField;

        private string mOBILEField;

        private string eMAILField;

        /// <remarks/>
        public int ID
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

        /// <remarks/>
        public string PRIMARY
        {
            get
            {
                return this.pRIMARYField;
            }
            set
            {
                this.pRIMARYField = value;
            }
        }

        /// <remarks/>
        public string SHIPMENT
        {
            get
            {
                return this.sHIPMENTField;
            }
            set
            {
                this.sHIPMENTField = value;
            }
        }

        /// <remarks/>
        public string FIRSTNAME
        {
            get
            {
                return this.fIRSTNAMEField;
            }
            set
            {
                this.fIRSTNAMEField = value;
            }
        }

        public string MIDDLENAME
        {
            get
            {
                return this.mIDDLENAMEField;
            }
            set
            {
                this.mIDDLENAMEField = value;
            }
        }

        /// <remarks/>
        public string LASTNAME
        {
            get
            {
                return this.lASTNAMEField;
            }
            set
            {
                this.lASTNAMEField = value;
            }
        }

        public string COMPANYNAME
        {
            get
            {
                return this.cOMPANYNAMEField;
            }
            set
            {
                this.cOMPANYNAMEField = value;
            }
        }

        /// <remarks/>
        //[System.Xml.Serialization.XmlElementAttribute(DataType = "date")]
        ///\public System.DateTime DOB
        public String DOB
        {
            get
            {
                return this.dOBField;
            }
            set
            {
                this.dOBField = value;
            }
        }

        /// <remarks/>
        public string STREET
        {
            get
            {
                return this.sTREETField;
            }
            set
            {
                this.sTREETField = value;
            }
        }

        /// <remarks/>
        public string CITY
        {
            get
            {
                return this.cITYField;
            }
            set
            {
                this.cITYField = value;
            }
        }

        /// <remarks/>
        public string STATE
        {
            get
            {
                return this.sTATEField;
            }
            set
            {
                this.sTATEField = value;
            }
        }

        /// <remarks/>
        public string MOBILE
        {
            get
            {
                return this.mOBILEField;
            }
            set
            {
                this.mOBILEField = value;
            }
        }

        /// <remarks/>
        public string EMAIL
        {
            get
            {
                return this.eMAILField;
            }
            set
            {
                this.eMAILField = value;
            }
        }
    }


}