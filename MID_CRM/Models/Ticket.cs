using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;

namespace MID_CRM.Models
{
    /// <summary>
    /// Root object for the VO_TICKETS XML response.
    /// </summary>
    [XmlRoot("VO_TICKETS", IsNullable = false)]
    public partial class VO_TICKETS //VO_TICKETS
    {
        private VO_TICKET[] vO_TICKETField;

        /// <summary/>
        [XmlElement("VO_TICKET")]
        public VO_TICKET[] VO_TICKET
        {
            get
            {
                return this.vO_TICKETField;
            }
            set
            {
                this.vO_TICKETField = value;
            }
        }
    }

    /// <summary>
    /// Represents an individual ticket.
    /// </summary>
    public partial class VO_TICKET
    {
        private string vO_STATUSField;

        private string vO_CREATION_DATEField;

        private string vO_DUE_DATEField;

        private string vO_SOURCEField;

        private string vO_CONTACT_METHODField;

        private string vO_SYNOPSISField;

        private string vO_CATEGORYField;

        private string vO_AREAField;

        private string vO_TYPEField;

        private VO_NOTE[] vO_NOTESField;

        /// <summary/>
        [XmlElement("VO_STATUS")]
        public string VO_STATUS
        {
            get
            {
                return this.vO_STATUSField;
            }
            set
            {
                this.vO_STATUSField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_CREATION_DATE")]
        public string VO_CREATION_DATE
        {
            get
            {
                return this.vO_CREATION_DATEField;
            }
            set
            {
                this.vO_CREATION_DATEField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_DUE_DATE")]
        public string VO_DUE_DATE
        {
            get
            {
                return this.vO_DUE_DATEField;
            }
            set
            {
                this.vO_DUE_DATEField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_SOURCE")]
        public string VO_SOURCE
        {
            get
            {
                return this.vO_SOURCEField;
            }
            set
            {
                this.vO_SOURCEField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_CONTACT_METHOD")]
        public string VO_CONTACT_METHOD
        {
            get
            {
                return this.vO_CONTACT_METHODField;
            }
            set
            {
                this.vO_CONTACT_METHODField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_SYNOPSIS")]
        public string VO_SYNOPSIS
        {
            get
            {
                return this.vO_SYNOPSISField;
            }
            set
            {
                this.vO_SYNOPSISField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_CATEGORY")]
        public string VO_CATEGORY
        {
            get
            {
                return this.vO_CATEGORYField;
            }
            set
            {
                this.vO_CATEGORYField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_AREA")]
        public string VO_AREA
        {
            get
            {
                return this.vO_AREAField;
            }
            set
            {
                this.vO_AREAField = value;
            }
        }

        /// <summary/>
        [XmlElement("VO_TYPE")]
        public string VO_TYPE
        {
            get
            {
                return this.vO_TYPEField;
            }
            set
            {
                this.vO_TYPEField = value;
            }
        }

        /// <summary/>
        [XmlArray("VO_NOTES")]
        [XmlArrayItem("VO_NOTE")]
        public VO_NOTE[] VO_NOTES
        {
            get
            {
                return this.vO_NOTESField;
            }
            set
            {
                this.vO_NOTESField = value;
            }
        }
    }

    /// <summary>
    /// Represents a note belonging to a ticket.
    /// </summary>
    public partial class VO_NOTE
    {
        private string vO_NOTEField;

        /// <summary/>
        [XmlText]
        public string Value
        {
            get
            {
                return this.vO_NOTEField;
            }
            set
            {
                this.vO_NOTEField = value;
            }
        }
    }
}
