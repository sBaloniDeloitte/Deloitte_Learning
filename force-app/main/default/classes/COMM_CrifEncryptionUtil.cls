/**
* @File Name : CrifEncryptionUtil .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 31, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 31, 2025 |   | Initial Version
**/

	public class COMM_CrifEncryptionUtil {

		public static final String ENCRYPTION_KEY = '5496056975VCUKJA';
		public static final String ENCRYPTION_IV  = '5077672295OOFQCS';

		public static String prepareEncryptedCrifRequest(String xmlBody) {
			try {
				// Convert key and IV to Blob
				Blob keyBlob = Blob.valueOf(ENCRYPTION_KEY);
				Blob ivBlob = Blob.valueOf(ENCRYPTION_IV);

				// Convert the XML to Blob
				Blob inputBlob = Blob.valueOf(xmlBody);

				// Encrypt the input XML
				Blob encryptedBlob = Crypto.encrypt('AES128', keyBlob, ivBlob, inputBlob);

				// Base64 encode the encrypted data
				String base64Encrypted = EncodingUtil.base64Encode(encryptedBlob);

				

				// Return the final JSON string
				return base64Encrypted;

			} catch (Exception e) {
				System.debug('Encryption Error: ' + e.getMessage());
				return null;
			}
		}
	}