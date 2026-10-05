using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models.Sub
{

    // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    [System.Xml.Serialization.XmlRootAttribute(IsNullable = false)]
    public partial class PRODUCT
    {

        private string cODEField;

        private string dESCRIPTIONField;

        private PRODUCTSERVICE[] sERVICEField;

        private PRODUCTSUB_PRODUCT[] sUB_PRODUCTField;

        private string pACKAGE_TYPEField;

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
        public string DESCRIPTION
        {
            get
            {
                return this.dESCRIPTIONField;
            }
            set
            {
                this.dESCRIPTIONField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("SERVICE")]
        public PRODUCTSERVICE[] SERVICE
        {
            get
            {
                return this.sERVICEField;
            }
            set
            {
                this.sERVICEField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("SUB_PRODUCT")]
        public PRODUCTSUB_PRODUCT[] SUB_PRODUCT
        {
            get
            {
                return this.sUB_PRODUCTField;
            }
            set
            {
                this.sUB_PRODUCTField = value;
            }
        }

        /// <remarks/>
        public string PACKAGE_TYPE
        {
            get
            {
                return this.pACKAGE_TYPEField;
            }
            set
            {
                this.pACKAGE_TYPEField = value;
            }
        }
    }

    /// <remarks/>
    //[System.SerializableAttribute()]
    //[System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSERVICE
    {

        private int idField;

        private decimal? rC_CHARGEField;

        private decimal? oT_CHARGEField;

        //private PRODUCTSERVICEBDU_LIST bDU_LISTField;
        private PRODUCTSERVICEBDU_LIST[] bDU_LISTField;        

        private string cREATION_DATEField;

        private string aCTIVATION_DATEField;

        private string eXPIRATION_DATEField;

        private string cODEField;

        private string dESCRIPTIONField;

        private string tYPEField;

        //11.23.2021
        private string gROUPField;

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
        public decimal? RC_CHARGE
        {
            get
            {
                return this.rC_CHARGEField;
            }
            set
            {
                this.rC_CHARGEField = value;
            }
        }

        /// <remarks/>
        public decimal? OT_CHARGE
        {
            get
            {
                return this.oT_CHARGEField;
            }
            set
            {
                this.oT_CHARGEField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("BDU", IsNullable = false)]
        public PRODUCTSERVICEBDU_LIST[] BDU_LIST
        {
            get
            {
                return this.bDU_LISTField;
            }
            set
            {
                this.bDU_LISTField = value;
            }
        }

        /// <remarks/>
        public string CREATION_DATE
        {
            get
            {
                return this.cREATION_DATEField;
            }
            set
            {
                this.cREATION_DATEField = value;
            }
        }

        /// <remarks/>
        public string ACTIVATION_DATE
        {
            get
            {
                return this.aCTIVATION_DATEField;
            }
            set
            {
                this.aCTIVATION_DATEField = value;
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
        public string DESCRIPTION
        {
            get
            {
                return this.dESCRIPTIONField;
            }
            set
            {
                this.dESCRIPTIONField = value;
            }
        }

        /// <remarks/>
        public string TYPE
        {
            get
            {
                return this.tYPEField;
            }
            set
            {
                this.tYPEField = value;
            }
        }

        //11.23.2021
        public string GROUP
        {
            get
            {
                return this.gROUPField;
            }
            set
            {
                this.gROUPField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/

    /*--------- Commented 09.21.2021
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSERVICEBDU_LIST
    {

        private PRODUCTSERVICEBDU_LISTBDU bDUField;

        /// <remarks/>
        public PRODUCTSERVICEBDU_LISTBDU BDU
        {
            get
            {
                return this.bDUField;
            }
            set
            {
                this.bDUField = value;
            }
        }
    }*/

    public partial class PRODUCTSERVICEBDU_LIST
    {
        private string nAMEField;

        private byte uNIT_CODEField;

        private string uNIT_DESCRIPTIONField;

        private decimal bALANCEField;

        private decimal uSEDField;

        private string fROM_DATEField;

        private string tO_DATEField;

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
        public byte UNIT_CODE
        {
            get
            {
                return this.uNIT_CODEField;
            }
            set
            {
                this.uNIT_CODEField = value;
            }
        }

        /// <remarks/>
        public string UNIT_DESCRIPTION
        {
            get
            {
                return this.uNIT_DESCRIPTIONField;
            }
            set
            {
                this.uNIT_DESCRIPTIONField = value;
            }
        }

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
        public decimal USED
        {
            get
            {
                return this.uSEDField;
            }
            set
            {
                this.uSEDField = value;
            }
        }

        /// <remarks/>
        public string FROM_DATE
        {
            get
            {
                return this.fROM_DATEField;
            }
            set
            {
                this.fROM_DATEField = value;
            }
        }

        /// <remarks/>
        public string TO_DATE
        {
            get
            {
                return this.tO_DATEField;
            }
            set
            {
                this.tO_DATEField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]*/
    /*--- Commented 09.21.2021
    public partial class PRODUCTSERVICEBDU_LISTBDU
    {

        private string nAMEField;

        private byte uNIT_CODEField;

        private string uNIT_DESCRIPTIONField;

        private decimal bALANCEField;

        private decimal uSEDField;

        private string fROM_DATEField;

        private string tO_DATEField;

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
        public byte UNIT_CODE
        {
            get
            {
                return this.uNIT_CODEField;
            }
            set
            {
                this.uNIT_CODEField = value;
            }
        }

        /// <remarks/>
        public string UNIT_DESCRIPTION
        {
            get
            {
                return this.uNIT_DESCRIPTIONField;
            }
            set
            {
                this.uNIT_DESCRIPTIONField = value;
            }
        }

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
        public decimal USED
        {
            get
            {
                return this.uSEDField;
            }
            set
            {
                this.uSEDField = value;
            }
        }

        /// <remarks/>
        public string FROM_DATE
        {
            get
            {
                return this.fROM_DATEField;
            }
            set
            {
                this.fROM_DATEField = value;
            }
        }

        /// <remarks/>
        public string TO_DATE
        {
            get
            {
                return this.tO_DATEField;
            }
            set
            {
                this.tO_DATEField = value;
            }
        }
    }*/

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSUB_PRODUCT
    {

        private string cODEField;

        private string dESCRIPTIONField;

        private PRODUCTSUB_PRODUCTSERVICE[] sERVICEField;

        //private PRODUCTSUB_PRODUCTSUB_PRODUCT sUB_PRODUCTField;
        private PRODUCTSUB_PRODUCTSUB_PRODUCT[] sUB_PRODUCTField;

        private string pACKAGE_TYPEField;

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
        public string DESCRIPTION
        {
            get
            {
                return this.dESCRIPTIONField;
            }
            set
            {
                this.dESCRIPTIONField = value;
            }
        }

        /// <remarks/>        
        [System.Xml.Serialization.XmlElementAttribute("SERVICE")]
        public PRODUCTSUB_PRODUCTSERVICE[] SERVICE
        {
            get
            {
                return this.sERVICEField;
            }
            set
            {
                this.sERVICEField = value;
            }
        }

        /// <remarks/>
        // Added below 09.21.2021
        [System.Xml.Serialization.XmlElementAttribute("SUB_PRODUCT")]
        public PRODUCTSUB_PRODUCTSUB_PRODUCT[] SUB_PRODUCT
        {
            get
            {
                return this.sUB_PRODUCTField;
            }
            set
            {
                this.sUB_PRODUCTField = value;
            }
        }

        /// <remarks/>
        public string PACKAGE_TYPE
        {
            get
            {
                return this.pACKAGE_TYPEField;
            }
            set
            {
                this.pACKAGE_TYPEField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSUB_PRODUCTSERVICE
    {

        private int idField;

        private decimal? rC_CHARGEField;

        private decimal? oT_CHARGEField;

        private PRODUCTSUB_PRODUCTSERVICEBDU[] bDU_LISTField;

        private string cREATION_DATEField;

        private string aCTIVATION_DATEField;

        private string eXPIRATION_DATEField;

        private string cODEField;

        private string dESCRIPTIONField;

        private string tYPEField;

        private string gROUPField;

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
        public decimal? RC_CHARGE
        {
            get
            {
                return this.rC_CHARGEField;
            }
            set
            {
                this.rC_CHARGEField = value;
            }
        }

        /// <remarks/>
        public decimal? OT_CHARGE
        {
            get
            {
                return this.oT_CHARGEField;
            }
            set
            {
                this.oT_CHARGEField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("BDU", IsNullable = false)]
        public PRODUCTSUB_PRODUCTSERVICEBDU[] BDU_LIST
        {
            get
            {
                return this.bDU_LISTField;
            }
            set
            {
                this.bDU_LISTField = value;
            }
        }

        /// <remarks/>
        public string CREATION_DATE
        {
            get
            {
                return this.cREATION_DATEField;
            }
            set
            {
                this.cREATION_DATEField = value;
            }
        }

        /// <remarks/>
        public string ACTIVATION_DATE
        {
            get
            {
                return this.aCTIVATION_DATEField;
            }
            set
            {
                this.aCTIVATION_DATEField = value;
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
        public string DESCRIPTION
        {
            get
            {
                return this.dESCRIPTIONField;
            }
            set
            {
                this.dESCRIPTIONField = value;
            }
        }

        /// <remarks/>
        public string TYPE
        {
            get
            {
                return this.tYPEField;
            }
            set
            {
                this.tYPEField = value;
            }
        }

        /// <remarks/>
        public string GROUP
        {
            get
            {
                return this.gROUPField;
            }
            set
            {
                this.gROUPField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSUB_PRODUCTSERVICEBDU
    {

        private string nAMEField;

        private byte uNIT_CODEField;

        private string uNIT_DESCRIPTIONField;

        private decimal bALANCEField;

        private decimal uSEDField;

        private string fROM_DATEField;

        private string tO_DATEField;

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
        public byte UNIT_CODE
        {
            get
            {
                return this.uNIT_CODEField;
            }
            set
            {
                this.uNIT_CODEField = value;
            }
        }

        /// <remarks/>
        public string UNIT_DESCRIPTION
        {
            get
            {
                return this.uNIT_DESCRIPTIONField;
            }
            set
            {
                this.uNIT_DESCRIPTIONField = value;
            }
        }

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
        public decimal USED
        {
            get
            {
                return this.uSEDField;
            }
            set
            {
                this.uSEDField = value;
            }
        }

        /// <remarks/>
        public string FROM_DATE
        {
            get
            {
                return this.fROM_DATEField;
            }
            set
            {
                this.fROM_DATEField = value;
            }
        }

        /// <remarks/>
        public string TO_DATE
        {
            get
            {
                return this.tO_DATEField;
            }
            set
            {
                this.tO_DATEField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSUB_PRODUCTSUB_PRODUCT
    {

        private string cODEField;

        private string dESCRIPTIONField;

        private PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICE[] sERVICEField;

        private string pACKAGE_TYPEField;

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
        public string DESCRIPTION
        {
            get
            {
                return this.dESCRIPTIONField;
            }
            set
            {
                this.dESCRIPTIONField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("SERVICE")]
        public PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICE[] SERVICE
        {
            get
            {
                return this.sERVICEField;
            }
            set
            {
                this.sERVICEField = value;
            }
        }

        /// <remarks/>
        public string PACKAGE_TYPE
        {
            get
            {
                return this.pACKAGE_TYPEField;
            }
            set
            {
                this.pACKAGE_TYPEField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICE
    {

        private int idField;

        private decimal? rC_CHARGEField;

        private decimal? oT_CHARGEField;

        //private PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LIST bDU_LISTField;
        private PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LIST[] bDU_LISTField;

        private string cREATION_DATEField;

        private string aCTIVATION_DATEField;

        private string eXPIRATION_DATEField;

        private string cODEField;

        private string dESCRIPTIONField;

        private string tYPEField;

        private string gROUPField;

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
        public decimal? RC_CHARGE
        {
            get
            {
                return this.rC_CHARGEField;
            }
            set
            {
                this.rC_CHARGEField = value;
            }
        }

        /// <remarks/>
        public decimal? OT_CHARGE
        {
            get
            {
                return this.oT_CHARGEField;
            }
            set
            {
                this.oT_CHARGEField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("BDU", IsNullable = false)]
        public PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LIST[] BDU_LIST
        {
            get
            {
                return this.bDU_LISTField;
            }
            set
            {
                this.bDU_LISTField = value;
            }
        }

        /// <remarks/>
        public string CREATION_DATE
        {
            get
            {
                return this.cREATION_DATEField;
            }
            set
            {
                this.cREATION_DATEField = value;
            }
        }

        /// <remarks/>
        public string ACTIVATION_DATE
        {
            get
            {
                return this.aCTIVATION_DATEField;
            }
            set
            {
                this.aCTIVATION_DATEField = value;
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
        public string DESCRIPTION
        {
            get
            {
                return this.dESCRIPTIONField;
            }
            set
            {
                this.dESCRIPTIONField = value;
            }
        }

        /// <remarks/>
        public string TYPE
        {
            get
            {
                return this.tYPEField;
            }
            set
            {
                this.tYPEField = value;
            }
        }

        /// <remarks/>
        public string GROUP
        {
            get
            {
                return this.gROUPField;
            }
            set
            {
                this.gROUPField = value;
            }
        }
    }

    /// <remarks/>
    /*[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]*/

    /*-----Commented 09212021
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LIST
{

    private PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LISTBDU bDUField;       

    /// <remarks/>
    public PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LISTBDU BDU
    {
        get
        {
            return this.bDUField;
        }
        set
        {
            this.bDUField = value;
        }
    }
}*/

   
    public partial class PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LIST
    {
        private string nAMEField;

        private byte uNIT_CODEField;

        private string uNIT_DESCRIPTIONField;

        private decimal bALANCEField;

        private decimal uSEDField;

        private string fROM_DATEField;

        private string tO_DATEField;

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
        public byte UNIT_CODE
        {
            get
            {
                return this.uNIT_CODEField;
            }
            set
            {
                this.uNIT_CODEField = value;
            }
        }

        /// <remarks/>
        public string UNIT_DESCRIPTION
        {
            get
            {
                return this.uNIT_DESCRIPTIONField;
            }
            set
            {
                this.uNIT_DESCRIPTIONField = value;
            }
        }

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
        public decimal USED
        {
            get
            {
                return this.uSEDField;
            }
            set
            {
                this.uSEDField = value;
            }
        }

        /// <remarks/>
        public string FROM_DATE
        {
            get
            {
                return this.fROM_DATEField;
            }
            set
            {
                this.fROM_DATEField = value;
            }
        }

        /// <remarks/>
        public string TO_DATE
        {
            get
            {
                return this.tO_DATEField;
            }
            set
            {
                this.tO_DATEField = value;
            }
        }
    }


    /// <remarks/>
    /* [System.SerializableAttribute()]
     [System.ComponentModel.DesignerCategoryAttribute("code")]*/

     /* --- Commented 09.21.2021
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class PRODUCTSUB_PRODUCTSUB_PRODUCTSERVICEBDU_LISTBDU
    {

        private string nAMEField;

        private byte uNIT_CODEField;

        private string uNIT_DESCRIPTIONField;

        private decimal bALANCEField;

        private decimal uSEDField;

        private string fROM_DATEField;

        private string tO_DATEField;

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
        public byte UNIT_CODE
        {
            get
            {
                return this.uNIT_CODEField;
            }
            set
            {
                this.uNIT_CODEField = value;
            }
        }

        /// <remarks/>
        public string UNIT_DESCRIPTION
        {
            get
            {
                return this.uNIT_DESCRIPTIONField;
            }
            set
            {
                this.uNIT_DESCRIPTIONField = value;
            }
        }

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
        public decimal USED
        {
            get
            {
                return this.uSEDField;
            }
            set
            {
                this.uSEDField = value;
            }
        }

        /// <remarks/>
        public string FROM_DATE
        {
            get
            {
                return this.fROM_DATEField;
            }
            set
            {
                this.fROM_DATEField = value;
            }
        }

        /// <remarks/>
        public string TO_DATE
        {
            get
            {
                return this.tO_DATEField;
            }
            set
            {
                this.tO_DATEField = value;
            }
        }
    }*/



}