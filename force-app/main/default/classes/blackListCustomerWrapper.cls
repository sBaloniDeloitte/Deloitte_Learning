public class blackListCustomerWrapper {
    public List<List<String>> data;
    public Boolean done;
    public String endTime;
    public Metadata metadata;
    public String queryId;
    public Integer rowCount;
    public String startTime;

    public class Metadata {
        public FieldMetadata mobilenumber;
        public FieldMetadata address;
        public FieldMetadata custcrcpr;
        public FieldMetadata custlname;
        public FieldMetadata custfname;
        public FieldMetadata custcif;
        public FieldMetadata custdob;
        public FieldMetadata hybrid_score;
        public FieldMetadata vector_score;
        public FieldMetadata Input_param;
        public FieldMetadata keyword_score;
    }

    public class FieldMetadata {
        public Integer placeInOrder;
        public String type;
        public Integer typeCode;
    }
}