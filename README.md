# Infrastructure-As-Code
This is a repository for the cloud computing project on Infrastructure as Code using Terraform and Ansible.

Team: Faiz Usmani, Parag Tambalkar, Pranay Raman, Shubham Girdhar

Tools and Technologies used:
1. Terraform – The Maestro Provisioner
2. Ansible – The Configuration Expert
3. Azure and Cloud Shell – Cloud and Command-line Specialists
4. Visual Studio 2019 – The Pro IDE

Deployment Plan:
1. The user will log in to the Azure portal and use Azure Cloud Shell to run Terraform and Ansible scripts.
2. Terraform scripts are run and a resource group with two Windows VMs having proper network configurations is created.
3. After the successful creation of VMs, IIS (Internet Information Services – a web server software package specifically designed for windows) and some other modules are configured on both of the VMs using their IP’s. They are required to run an ASP.NET web app on a Windows server.
4. A self-created web app or app cloned from the provided GitHub link is published on both of the VMs using Visual Studio 2019 and accessed through the public IP of the load balancer.

The detailed documentation about the implementation can be found [here](Documentation/Infrastructure_as_code_v4.pdf).
