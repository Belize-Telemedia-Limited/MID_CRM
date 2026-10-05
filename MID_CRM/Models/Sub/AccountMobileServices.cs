using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MID_CRM.Models.Sub
{
    

        // NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
        /// <remarks/>
        //[System.SerializableAttribute()]
        //[System.ComponentModel.DesignerCategoryAttribute("code")]
        //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        //[System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
        public partial class Services
        {

            private ServicesAccount[] accountField;

            /// <remarks/>
            [System.Xml.Serialization.XmlElementAttribute("Account")]
            public ServicesAccount[] Account
            {
                get
                {
                    return this.accountField;
                }
                set
                {
                    this.accountField = value;
                }
            }
        }

        /// <remarks/>
        //[System.SerializableAttribute()]
        //[System.ComponentModel.DesignerCategoryAttribute("code")]
        //[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
        public partial class ServicesAccount
        {

            private string codeField;

            private string phonenumberField;

            private product productField;

            private primary_contact primary_contactField;

        /// <remarks/>
        public string code
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
            public string phonenumber
            {
                get
                {
                    return this.phonenumberField;
                }
                set
                {
                    this.phonenumberField = value;
                }
            }

            [System.Xml.Serialization.XmlElementAttribute("product")]
            public product product
            {
                get
                {
                    return this.productField;
                }
                set
                {
                    this.productField = value;
                }
            }

            [System.Xml.Serialization.XmlElementAttribute("primary_contact")]
            public primary_contact primary_contact
            {
                get
                {
                    return this.primary_contactField;
                }
                set
                {
                    this.primary_contactField = value;
                }
            }
    }

    public partial class product
    { private string codeField;
        private string typeField;

        public string code
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
        public string type
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

    }

    public partial class primary_contact
    {
        private Int32 idField;
        private string firstnameField;
        private string middlenameField;
        private string lastnameField;
        private string companynameField;

        public Int32 id
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

        public string firstname
        {
            get
            {
                return this.firstnameField;
            }
            set
            {
                this.firstnameField = value;
            }
        }

        public string middlename
        {
            get
            {
                return this.middlenameField;
            }
            set
            {
                this.middlenameField = value;
            }
        }

        public string lastname
        {
            get
            {
                return this.lastnameField;
            }
            set
            {
                this.lastnameField = value;
            }
        }

        public string companyname
        {
            get
            {
                return this.companynameField;
            }
            set
            {
                this.companynameField = value;
            }
        }
    }    

}
