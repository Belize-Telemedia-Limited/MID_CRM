using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;

namespace MID_CRM.Models
{

    // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    [System.Xml.Serialization.XmlRootAttribute(IsNullable = false)]
    public partial class BALANCE
    {

        private BALANCEPRIMARY pRIMARYField;

        private BALANCEBONUS bONUSField;

        private BALANCECREDITMI cREDITMIField;

        /// <remarks/>
        public BALANCEPRIMARY PRIMARY
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
        public BALANCEBONUS BONUS
        {
            get
            {
                return this.bONUSField;
            }
            set
            {
                this.bONUSField = value;
            }
        }

        /// <remarks/>
        public BALANCECREDITMI CREDITMI
        {
            get
            {
                return this.cREDITMIField;
            }
            set
            {
                this.cREDITMIField = value;
            }
        }
    }

    /// <remarks/>
   /* [System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    public partial class BALANCEPRIMARY
    {

        private decimal bALANCEField;

        private string eXPIRATION_DATEField;

        /// <remarks/>
        public decimal BALANCE
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
        public string EXPIRATION_DATE
        {
            get
            {
                return this.eXPIRATION_DATEField;
            }
            set
            {
                this.eXPIRATION_DATEField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    public partial class BALANCEBONUS
    {

        private decimal bALANCEField;

        private string eXPIRATION_DATEField;

        /// <remarks/>
        public decimal BALANCE
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
        public string EXPIRATION_DATE
        {
            get
            {
                return this.eXPIRATION_DATEField;
            }
            set
            {
                this.eXPIRATION_DATEField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
  
    public partial class BALANCECREDITMI
    {
        
        private decimal bALANCEField;

        
        private decimal fEEField;

        private string eXPIRATION_DATEField;

        /// <remarks/>
        public decimal BALANCE
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
        public decimal FEE
        {
            get
            {
                return this.fEEField;
            }
            set
            {
                this.fEEField = value;
            }
        }

        /// <remarks/>
        public string EXPIRATION_DATE
        {
            get
            {
                return this.eXPIRATION_DATEField;
            }
            set
            {
                this.eXPIRATION_DATEField = value;
            }
        }
    }


}