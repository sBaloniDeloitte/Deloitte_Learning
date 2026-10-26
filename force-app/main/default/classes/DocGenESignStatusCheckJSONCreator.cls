public with sharing class DocGenESignStatusCheckJSONCreator {
        public string did;	
        public String lan;	
        public Boolean linkRequried;
        public DocGenESignStatusCheckJSONCreator (string linkedRecId, string loanNumber, Boolean linkRequired)
        {
            this.did            =   linkedRecId;
            this.lan            =   loanNumber;
            this.linkRequried   =   linkRequired;
        }
}