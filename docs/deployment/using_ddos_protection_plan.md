# Considerations for the DDoS protection plan

Decide your approach for DDoS protection for your Information Assistant virtual network. If you simply don't want to use a DDoS protection plan simply leave the `USE_DDOS_PROTECTION_PLAN` variable set to `false`. 

If you plan to use a DDoS protection plan, you need to enable it by setting the `USE_DDOS_PROTECTION_PLAN` variable set to `true` and then you can select a specific DDoS protection plan in one of two ways:
   * **RECOMMENDED:** You can manually provide the DDoS plan ID in your azd parameters. Be sure to update the subscription id, resource group name, and DDoS plan name values.

       ```bash
       azd env set USE_DDOS_PROTECTION_PLAN true
       azd env set DDOS_PLAN_ID "/subscriptions/{subscription id}/resourceGroups/{resource group name}/providers/Microsoft.Network/ddosProtectionPlans/{ddos plan name}"
       ```

   * You can let the deployment choose a DDoS protection plan at deployment time. If you do not provide the parameter above, the deployment scripts will prompt you with a choice to use the first found existing DDoS plan in your subscription or Information Assistant will create one automatically.
   ***IMPORTANT: The script can only detect DDoS protection plans in the same Azure subscription you are logged into.***

      The prompt will appear like the following when running `azd up`:

      ```bash
      Found existing DDOS Protection Plan: /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/infoasst-xxxxxxx/providers/Microsoft.Network/ddosProtectionPlans/my_ddos_plan
      Do you want to use this existing DDOS Protection Plan (y/n)? 
      ```

      Or if no DDoS plan is found in the subscription the script will simply ouput:

      ```bash
      No existing DDOS protection plan found. Terraform will create a new one.
      ```