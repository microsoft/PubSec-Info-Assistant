# Known Issues

Here are some commonly encountered issues when deploying the PS Info Assistant Accelerator.

## This subscription cannot create CognitiveServices until you agree to Responsible AI terms for this resource

```bash
Error: This subscription cannot create CognitiveServices until you agree to Responsible AI terms for this resource. You can agree to Responsible AI terms by creating a resource through the Azure Portal then trying again. For more detail go to https://aka.ms/csrainotice"}]

```

**Solution** : Manually create a "Cognitive services multi-service account" in your Azure Subscription and Accept "Responsible AI Notice"
