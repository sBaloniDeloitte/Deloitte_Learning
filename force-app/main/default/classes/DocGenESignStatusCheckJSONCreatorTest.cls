@IsTest
public class DocGenESignStatusCheckJSONCreatorTest {

    @IsTest
    static void testConstructorInitialization() {
        String linkedRecId = '006XXXXXXXXXXXX';
        String loanNumber = 'LAN-12345';
        Boolean linkRequired = true;
        DocGenESignStatusCheckJSONCreator obj = new DocGenESignStatusCheckJSONCreator(linkedRecId, loanNumber, linkRequired);
        System.assertEquals(linkedRecId, obj.did, 'Linked record Id mismatch');
        System.assertEquals(loanNumber, obj.lan, 'Loan number mismatch');
        System.assertEquals(linkRequired, obj.linkRequried, 'LinkRequired flag mismatch');
    }
}