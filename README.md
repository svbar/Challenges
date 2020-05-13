# Infra-challenges

Challenge-1:
Create a 3- Tier Architecture infra setup.

Solution:
Tech Stack:
 - Terraform
  - AWS Cloud
  
```Tier 1 - Presentation Layer include:```
   - A Web Server 
   - Placed in DMZ
   - Ports : 443, 22
   - Seperate Subnet 192.168.10.0/24
 ```Tier 2 - Application Server/equivaent```
   - A web server + App server
   - Ports :8080, 22
   - Placed in its own subnet - 192.168.20.0/24
 ```Tier 3 - DB Layer```
   - AWS RDS Instance
   - Ports 3306
   - Placed in its own subnet - 192.168.30.0/24
   Management Server/ Jump Server to manage all the assets
   - Ports 22
  
   
