````markdown
# Azure Small Business Infrastructure Demo

This project deploys a foundational, secure, and scalable infrastructure for a hypothetical small business on Microsoft Azure. The entire environment is defined and managed as code using Terraform, demonstrating best practices for automation and resource management in the cloud.

This project is a portfolio piece designed to showcase core skills required for an Azure Administrator role.

## Architecture Diagram

A high-level diagram of the infrastructure deployed by this Terraform code.

*A simple diagram showing the components below should be embedded here.*

 ```mermaid
        graph TD
            subgraph "Azure Region: West US 2"
                subgraph "Resource Group: MyDemoProject-RG"
                    A[<font size=5>🌐</font><br>Internet] --> B(Public IP);
    
            subgraph "VNet: MyDemo-VNet"
                   subgraph "Subnet: Web-Subnet"
                         C(VM: Web-VM) --> D(Network<br>Interface);
                     end
                 end

                 D --> B;
                 E(NSG: Web-Subnet-NSG<br>Allow RDP) -.-> Subnet;
             end
         end

*Diagram components: VNet -> Subnet -> NSG -> VM with a Public IP*

## Skills & Features Demonstrated

This project showcases the following Azure and DevOps competencies:

*   **Infrastructure as Code (IaC):** All resources are defined declaratively using **Terraform**.
*   **Core Networking:**
    *   Creation of a **Virtual Network (VNet)** to provide an isolated network environment.
    *   Segmentation using **Subnets** for organizing resources.
*   **Network Security:**
    *   Implementation of a **Network Security Group (NSG)**.
    *   Configuration of an inbound security rule to allow **RDP access** for administration.
*   **Compute:**
    *   Deployment of a **Windows Server Virtual Machine**.
*   **Public IP & Connectivity:**
    *   Allocation of a **Standard SKU Public IP address** for external access.
*   **Resource Management:**
    *   Logical grouping of all resources within a single **Resource Group**.

## Technologies Used

*   **Microsoft Azure**
*   **Terraform**
*   **Azure CLI**

## How to Deploy

### Prerequisites

1.  **Azure CLI:** You must have the Azure CLI installed.
2.  **Terraform:** You must have Terraform installed.
3.  **Azure Subscription:** An active Azure subscription (Pay-As-You-Go is sufficient).

### Deployment Steps

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-directory>
    ```

2.  **Log in to Azure:**
    ```bash
    az login
    ```

3.  **Initialize Terraform:**
    This command downloads the necessary Azure provider plugin.
    ```bash
    terraform init
    ```

4.  **Plan the deployment:**
    This command shows you a preview of the resources that will be created.
    ```bash
    terraform plan
    ```

5.  **Apply the configuration:**
    This command builds the infrastructure. Type `yes` when prompted.
    ```bash
    terraform apply
    ```

## Deployed Resources

After running `terraform apply`, the following key resources will be created in your Azure subscription:

*   A Resource Group named `MyDemoProject-RG`.
*   A Virtual Network named `MyDemo-VNet`.
*   A Subnet named `Web-Subnet`.
*   A Network Security Group named `Web-Subnet-NSG` with a rule to allow RDP.
*   A Standard Public IP address.
*   A Network Interface.
*   A Windows Server Virtual Machine named `Web-VM`.

## Connecting to the VM

1.  After the `terraform apply` command completes, it will output the public IP address of the server.
2.  Use a Remote Desktop client to connect to this IP address.
3.  **Username:** `azureadmin`
4.  **Password:** The password you set in the `main.tf` file.

## Cleanup

To avoid ongoing charges, it is critical to destroy all resources when you are finished.

Run the following command to delete everything created by this project:
```bash
terraform destroy
```
````
