public class DocGenComJSONCreator {
   
        // public blob pdfFile;	
        public String contentId;	
        public String fileName;	
        public Integer compressionQuality;
        public DocGenComJSONCreator (string contentId, string fileName, Integer compQuality) //(blob pdf, string fileName, Integer compQuality)
        {
            // this.pdfFile            =   pdf;
            this.contentId          =   contentId;
            this.fileName           =   fileName;
            this.compressionQuality =   compQuality;
        }
}