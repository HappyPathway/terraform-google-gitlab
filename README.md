# terraform-google-gitlab
This module creates a Gitlab instance that is behind an IAP proxy. 

## Accessing 
In order to gain access to the Gitlab Web UI, you must be able to to authenticate to GCP as a user in the grp-gitlab-users group. If you are not currently a member of this group, please notify the infra team and we will be glad to add you if appropriate. 

Once you're able to authenticate to the IAP proxy, you should be able to proceed to the gitlab instance at https://git.cirr.dev. Gitlab authentication uses GSuite SAML. You should be able to easily create an account in Gitlab, given that you have a valid hawkfish.us email account. 

### SSH Access:
Prior to being able to access, you will need to make sure that you have gcloud installed. 
https://cloud.google.com/sdk/docs/downloads-interactive

Once gcloud has been installed, you will need to login to gcloud using 
```bash
gcloud auth login
```
This should open a webpage where you will authorize access to the app from your Hawkfish account. 

Adding the following to your ssh config will enable ssh access to gitlab. 
```bash
Host git.cirri.dev
  ProxyCommand gcloud beta compute start-iap-tunnel git01 22 --listen-on-stdin --project=hf-tf-p-platform-gitlab --zone=us-central1-a --verbosity=warning
```