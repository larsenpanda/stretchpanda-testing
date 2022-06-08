# Deploy and Test a Redpanda cluster stretched across regions
Terraform and ansible a 3 node Redpanda environment in AWS with public endpoints and do some testing

# Requirements:
 - Terraform
 - Ansible
 - Node.js

# Setup
- Clone the repo and enter directory
- Run ```npm install```
- Edit <b>main.tf</b> and change the following:
  - Regions as desired (Default: US-East-1, US-East-2, and US-West-2)
  - Edit CIDR block in VPC and Subnets (Default: 10.1.1.0/24, *<b>if you don't choose a CIDR block that is available it will complain when deploying the EC2's</b>*)
  - Instance type (Default: i3en.xlarge)
  - Volume Size (Default: 100GB)
  - All Tags, replace with your own <b>Name</b> of your environment to more easily find your resources in AWS

# 2 Ways to run it - In pieces or in one shot
## In pieces:
1. Run Terraform init: ```terraform init```
2. Run Terraform plan with an output: ```terraform plan -out=tfplan.out```
3. Run Terraform apply with the above output: ```terraform apply "tfplan.out"```
4. Output the Terraformed resources to JSON for use in the UI: ```terraform show -json > tf_out.json```
5. Generate the Ansible inventory file: ```node gethostnames.js```
6. Enter the "deployment-automation" directory and run the playbook: ```ansible-playbook --private-key ~/Downloads/larsenrp.pem -i hosts.ini -v ansible/playbooks/provision-node.yml``` <b>(Make sure to change the pem file to your own)</b>

## In one shot:
```terraform plan -out "tfplan.out" && terraform apply "tfplan.out" && terraform show -json > tf_out.json && node gethostnames.js && cd deployment-automation && ansible-playbook --private-key ~/Downloads/larsenrp.pem -i hosts.ini -v ansible/playbooks/provision-node.yml``` <b>(Make sure to change the pem file to your own)</b>

## Web UI:

From the root directory, run ```npm start```

Visit http://localhost:3000

The first time you visit the UI after starting up node you should paste the path to your pem key, which is handy for helper actions/text, it will remember it for however many times you refresh your page.

The "Stop RP" button on each instance ssh's in and does a ```systemctl stop redpanda``` and changes the button to "Start RP" which does a ```systemctl start redpanda```. This is helpful for testing failure while continuously producing.

Look at the helper commands down below, this gives some good copy/paste commands to run on the nodes you want to test from.

To stop the node.js process running the web UI run ```npm stop```

# Notes: 
The ```start-redpanda.yml```playbook was modified to change advertised kafka and rpc api's to be the public ip addresses from the inventory file, you can't just run the normal ansible playbooks provided by Redpanda
