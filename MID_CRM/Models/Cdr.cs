using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{

    // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
    /// <remarks/>
    /*[System.SerializableAttribute()]*/
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    [System.Xml.Serialization.XmlRootAttribute(IsNullable = false)]
    public partial class USAGE
    {

        private USAGEUSAGE_DETAILS[] uSAGE_DETAILSField;

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("USAGE_DETAILS")]
        public USAGEUSAGE_DETAILS[] USAGE_DETAILS
        {
            get
            {
                return this.uSAGE_DETAILSField;
            }
            set
            {
                this.uSAGE_DETAILSField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    public partial class USAGEUSAGE_DETAILS
    {

        private string cALLING_PARTYField;

        private string dESTINATION_PARTYField;

        private /*uint*/ string sTART_DATEField;

        private /*System.DateTime*/ string sTART_TIMEField;

        private string sERVICE_TYPEField;

        private /*byte*/ int cALL_DURATIONField;

        private decimal cHARGE_AMOUNTField;

        /// <remarks/>
        public string CALLING_PARTY
        {
            get
            {
                return this.cALLING_PARTYField;
            }
            set
            {
                this.cALLING_PARTYField = value;
            }
        }

        /// <remarks/>
        public string DESTINATION_PARTY
        {
            get
            {
                return this.dESTINATION_PARTYField;
            }
            set
            {
                this.dESTINATION_PARTYField = value;
            }
        }

        /// <remarks/>
        public string START_DATE
        {
            get
            {
                return this.sTART_DATEField;
            }
            set
            {
                this.sTART_DATEField = value;
            }
        }

        /// <remarks/>
        //[System.Xml.Serialization.XmlElementAttribute(DataType = "time")]
        public /*System.DateTime*/ string START_TIME
        {
            get
            {
                return this.sTART_TIMEField;
            }
            set
            {
                this.sTART_TIMEField = value;
            }
        }

        /// <remarks/>
        public string SERVICE_TYPE
        {
            get
            {
                return this.sERVICE_TYPEField;
            }
            set
            {
                this.sERVICE_TYPEField = value;
            }
        }

        /// <remarks/>
        public int CALL_DURATION
        {
            get
            {
                return this.cALL_DURATIONField;
            }
            set
            {
                this.cALL_DURATIONField = value;
            }
        }

        /// <remarks/>
        public decimal CHARGE_AMOUNT
        {
            get
            {
                return this.cHARGE_AMOUNTField;
            }
            set
            {
                this.cHARGE_AMOUNTField = value;
            }
        }
    }



}


/*
// NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
[System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
public partial class USAGE
{

    private USAGEUSAGE_DETAILS[] uSAGE_DETAILSField;

    /// <remarks/>
    [System.Xml.Serialization.XmlElementAttribute("USAGE_DETAILS")]
    public USAGEUSAGE_DETAILS[] USAGE_DETAILS
    {
        get
        {
            return this.uSAGE_DETAILSField;
        }
        set
        {
            this.uSAGE_DETAILSField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class USAGEUSAGE_DETAILS
{

    private uint cALLING_PARTYField;

    private ulong dESTINATION_PARTYField;

    private uint sTART_DATEField;

    private System.DateTime sTART_TIMEField;

    private string sERVICE_TYPEField;

    private byte cALL_DURATIONField;

    private decimal cHARGE_AMOUNTField;

    /// <remarks/>
    public uint CALLING_PARTY
    {
        get
        {
            return this.cALLING_PARTYField;
        }
        set
        {
            this.cALLING_PARTYField = value;
        }
    }

    /// <remarks/>
    public ulong DESTINATION_PARTY
    {
        get
        {
            return this.dESTINATION_PARTYField;
        }
        set
        {
            this.dESTINATION_PARTYField = value;
        }
    }

    /// <remarks/>
    public uint START_DATE
    {
        get
        {
            return this.sTART_DATEField;
        }
        set
        {
            this.sTART_DATEField = value;
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlElementAttribute(DataType = "time")]
    public System.DateTime START_TIME
    {
        get
        {
            return this.sTART_TIMEField;
        }
        set
        {
            this.sTART_TIMEField = value;
        }
    }

    /// <remarks/>
    public string SERVICE_TYPE
    {
        get
        {
            return this.sERVICE_TYPEField;
        }
        set
        {
            this.sERVICE_TYPEField = value;
        }
    }

    /// <remarks/>
    public byte CALL_DURATION
    {
        get
        {
            return this.cALL_DURATIONField;
        }
        set
        {
            this.cALL_DURATIONField = value;
        }
    }

    /// <remarks/>
    public decimal CHARGE_AMOUNT
    {
        get
        {
            return this.cHARGE_AMOUNTField;
        }
        set
        {
            this.cHARGE_AMOUNTField = value;
        }
    }
}

*/
