# Known Issues

Here are some commonly encountered issues when deploying the PS Info Assistant Accelerator.

## This subscription cannot create CognitiveServices until you agree to Responsible AI terms for this resource

```bash
Error: This subscription cannot create CognitiveServices until you agree to Responsible AI terms for this resource. You can agree to Responsible AI terms by creating a resource through the Azure Portal then trying again. For more detail go to https://aka.ms/csrainotice"}]

```

**Solution** : Manually create a "Cognitive services multi-service account" in your Azure Subscription and Accept "Responsible AI Notice"

1. In the Azure portal, navigate to the “Create a resource” page and search for “Cognitive Services”
2. Select “Cognitive Services” from the list of results and click “Create” 1.
3. On the “Create” page, provide the required information such as Subscription, Resource group, Region, Name, and Pricing tier 1.
4. Review and accept the terms "Responsible AI Notice"


---

## Error "Your adminstrator has configured the application infoasst_web_access_xxxxx to block users..."

By default Info Assistant deploys the webapp to require users to be a member of an Azure Active Directory Enterprise Application to access the website. If a user is not a member of the AAD EA they will receive this error:

![image.png](images/known_Issues_web_app_authentication.png)

### Solution

#### Option 1

Add the user to the Azure Active Directory Enterprise Application.

>1. Log into the Azure Portal
>2. Navigate to the App Service object in your resource group, named *infoasst-webapp-xxxxx*.
>3. View the **Authentication** tab. Select the "Identity Provider" link named *minted_webapp_access_xxxxx*.
>4. In the **Overview** tab, Select the link under the "Essentials" section labeled "Managed application in..." that should have a value like *infoasst_web_access_xxxxx*.
>5. Select the **Users and Groups** tab and use the **Add user/group** to add the user to the Azure Active Directory Enterprise Application.

#### Option 2

Turn off the option to require membership for the Azure Active Directory Enterprise Application.

>1. Log into the Azure Portal
>2. Navigate to the App Service object in your resource group, named *infoasst-webapp-xxxxx*.
>3. View the **Authentication** tab. Select the "Identity Provider" link named *infoasst_webapp_access_xxxxx*.
>4. In the **Overview** tab, Select the link under the "Essentials" section labeled "Managed application in..." that should have a value like *infoasst_webapp_access_xxxxx*.
>5. Select the **Properties** tab. Change the value for **Assignment Required** to No. Click **Save**.

---

## Errors due to throttling or overloading Form Recognizer

Occasionally you will hit a 429 return code in the FileFormRecSubmissionPDF which indicates that you need to retry your submission later, or an internal error returned by Form Recognzer in the FileFormRecPollingPDF function, which indicates the service has hit internal capacity issues. Both of these situations will occur under heavy load, but the accelerator is deisgned to back off and retry at a later time, up to a maxmum set of retries, which is configurable. These values surface as configuration settinsg in the Azure function and can be revised there, or they can be updated at deployment in function.bicep, or they can be updated in the file local.settings.json which is used when debugging a function in VS Code. These values are as follows...

```
@description('The maximum number of seconds  between uploading a file and submitting it to FR')
param maxSecondsHideOnUpload string

@description('The maximum number of times a file can be resubmitted to FR due to throttling or internal FR capacity limitations')
param maxSubmitRequeueCount string

@description('the number of seconds that a message sleeps before we try to poll for FR completion')
param pollQueueSubmitBackoff string

@description('The number of seconds a message sleeps before trying to resubmit due to throttling request from FR')
param pdfSubmitQueueBackoff string

@description('max times we will retry the submission due to throttling or internal errors in FR')
param maxPollingRequeueCount string

@description('number of seconds to delay before trying to resubmit a doc to FR when it reported an internal error')
param submitRequeueHideSeconds string

@description('The number of seconds we will hide a message before trying to repoll due to FR still processing a file. This is the default value that escalates exponentially')
param pollingBackoff string

@description('The maximum number of times we will retry to read a full processed document from FR. Failures in read may be due to network issues downloading the large response')
param maxReadAttempts string
```