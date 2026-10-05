using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models
{
    // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
    /// <remarks/>
    //[System.SerializableAttribute()]
    //[System.ComponentModel.DesignerCategoryAttribute("code")]
    //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    //[System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class Product
    {

        private string codeField;

        private Service[] servicesField;

        private ProductProduct[] subproductsField;

        /// <remarks/>
        public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("Service", IsNullable = false)]
        public Service[] Services
        {
            get
            {
                return this.servicesField;
            }
            set
            {
                this.servicesField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("Product", IsNullable = false)]
        public ProductProduct[] Subproducts
        {
            get
            {
                return this.subproductsField;
            }
            set
            {
                this.subproductsField = value;
            }
        }
    }

    /// <remarks/>
    //[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class Service
    {

        private string codeField;

        private string descriptionField;

        private decimal charge_RCField;

        private decimal charge_OTField;

        private string typeField;
        private string groupField;

        private Feature[] featuresField;

        private Bdu[] bdusField;

        /// <remarks/>
        public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }

        /// <remarks/>
        public string Description
        {
            get
            {
                return this.descriptionField;
            }
            set
            {
                this.descriptionField = value;
            }
        }

        /// <remarks/>
        public decimal Charge_RC
        {
            get
            {
                return this.charge_RCField;
            }
            set
            {
                this.charge_RCField = value;
            }
        }

        /// <remarks/>
        public decimal Charge_OT
        {
            get
            {
                return this.charge_OTField;
            }
            set
            {
                this.charge_OTField = value;
            }
        }

        public string Type
        {
            get
            {
                return this.typeField;
            }
            set
            {
                this.typeField = value;
            }
        }

        public string Group
        {
            get
            {
                return this.groupField;
            }
            set
            {
                this.groupField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("Feat")]
        public Feature[] Features
        {
            get
            {
                return this.featuresField;
            }
            set
            {
                this.featuresField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("Bdu")]
        public Bdu[] Bdus
        {
            get
            {
                return this.bdusField;
            }
            set
            {
                this.bdusField = value;
            }
        }
    }

    /// <remarks/>
    //[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class Feature
    {

        private string codeField;

        private string descriptionField;

        /// <remarks/>
        public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }

        /// <remarks/>
        public string Description
        {
            get
            {
                return this.descriptionField;
            }
            set
            {
                this.descriptionField = value;
            }
        }
    }

    /// <remarks/>
    //[System.SerializableAttribute()]    
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class Bdu
    {

        private string codeField;

        private string descriptionField;

        private int frequency_TypeField;

        private int quotaField;

        private int unit_CodeField;
        private string unit_DescriptionField;

        /// <remarks/>
        /// 
        public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }

        /// <remarks/>
        public string Description
        {
            get
            {
                return this.descriptionField;
            }
            set
            {
                this.descriptionField = value;
            }
        }

        public int Frequency_Type
        {
            get
            {
                return this.frequency_TypeField;
            }
            set
            {
                this.frequency_TypeField = value;
            }
        }

        /// <remarks/>
        public int Quota
        {
            get
            {
                return this.quotaField;
            }
            set
            {
                this.quotaField = value;
            }
        }

        public int Unit_Code
        {
            get
            {
                return this.unit_CodeField;
            }
            set
            {
                this.unit_CodeField = value;
            }
        }

        public string Unit_Description
        {
            get
            {
                return this.unit_DescriptionField;
            }
            set
            {
                this.unit_DescriptionField = value;
            }
        }
    }

    /// <remarks/>
    //[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ProductProduct
    {

        private string codeField;

        private string groupField;

        //private ProductProductSubProducts subProductsField; 

        private ProductProductProduct[] subProductsField;

        private Service[] servicesField;

        /// <remarks/>
        public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }

        public string Group
        {
            get
            {
                return this.groupField;
            }
            set
            {
                this.groupField = value;
            }
        }

        /// <remarks/>
        /*public ProductProductSubProducts SubProducts
        {
            get
            {
                return this.subProductsField;
            }
            set
            {
                this.subProductsField = value;
            }
        }*/

        [System.Xml.Serialization.XmlArrayItemAttribute("Product", IsNullable = false)]
        public ProductProductProduct[] SubProducts
        {
            get
            {
                return this.subProductsField;
            }
            set
            {
                this.subProductsField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("Service", IsNullable = false)]
        public Service[] Services
        {
            get
            {
                return this.servicesField;
            }
            set
            {
                this.servicesField = value;
            }
        }
    }

    /// <remarks/>
    //[System.SerializableAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ProductProductProduct
    {

        private string codeField;
        private string groupField;

        private Service[] servicesField;

        /// <remarks/>
        /// 
       public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }
        public string Group
        {
            get
            {
                return this.groupField;
            }
            set
            {
                this.groupField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("Service", IsNullable = false)]
        public Service[] Services
        {
            get
            {
                return this.servicesField;
            }
            set
            {
                this.servicesField = value;
            }
        }
    }
}