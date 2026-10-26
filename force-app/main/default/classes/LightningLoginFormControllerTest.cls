@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  System.assertNotEquals(controller, null);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  System.assertNotEquals(null, authConfig);
 }
    
 @IsTest
 static void testlogin() {
 	string userNameValue = 'helloworld@test.com';
    string passwordValue = 'testPassword';
    string urlParam = 'myTestUrl';
    LightningLoginFormController.login(userNameValue,passwordValue,urlParam); 
  	System.assertEquals(null,LightningLoginFormController.login(userNameValue,passwordValue,urlParam));
 }
    @IsTest
 static void testgetForgotPasswordUrl() {
    LightningLoginFormController.getForgotPasswordUrl(); 
  	System.assertEquals(null, LightningLoginFormController.getForgotPasswordUrl());
 }
    
 @IsTest
 static void testsetExperienceId() {
    LightningLoginFormController.setExperienceId('test'); 
  	System.assertNotEquals(null, LightningLoginFormController.setExperienceId('test'));
 }
}