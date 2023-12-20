rtshark-app

TODO:

Add addtional auth methods to the app to remove static authentication passwords
Allow capture interface selection
Allow online edit of filter ip's
Address the option to not install a bridge when you want capture on a stick


I developed rtshark-app with the specific purpose of facilitating on-site network diagnostics and remote monitoring, particularly for scenarios requiring a portable and deployable packet capture solution. This application is optimized for devices like the Orange Pi R1 and Raspberry Pi, which are ideal for situations where a compact, yet capable, network analysis tool is necessary.  

---

The primary design goal of `rtshark-app` is to make network monitoring and packet capturing accessible and manageable, even for individuals who may not have extensive experience with Linux or packet capture technologies. While tools like Wireshark offer powerful capabilities, they require a certain level of expertise and graphical support, which can be a challenge on lightweight devices. More importantly, Wireshark's graphical interface can be resource-intensive, leading to packet drops during intensive network monitoring tasks on low resource devices.

In contrast, `rtshark-app` is optimized for simplicity and efficiency. It's intended to be deployed in environments where a non-expert can easily initiate and manage packet capture processes. The user-friendly web interface of `rtshark-app` allows even those with minimal technical background to operate it effectively, enabling them to collect necessary network data and relay it back to more experienced users for in-depth analysis. This approach not only ensures comprehensive network monitoring but also reduces the learning curve and resource demands, making it ideal for use on less powerful devices.

--- 

A key feature of rtshark-app is its ability to create a bridge interface that combines two Ethernet interfaces. This functionality allows the device to act as an Ethernet tap, seamlessly integrating into a network for efficient packet capturing. This design choice caters to the needs of network troubleshooting, especially in mobile setups or environments where leaving a dedicated network monitoring device is required.

Certainly! Here's a synopsis for your `rtshark-app` that you can include in your README file:

---

## rtshark-app

`rtshark-app` is a comprehensive network monitoring solution designed to facilitate real-time packet capturing and analysis on network interfaces. Built on top of the powerful `tshark` utility, this Flask-based web application offers a user-friendly interface for managing and monitoring network traffic. Key features include starting and stopping packet capture, setting filters for specific IP addresses, and downloading captured packets for in-depth analysis.

### Key Features

- **Web Interface**: A Flask-based web application providing a simple and intuitive user interface.
- **Packet Capture Control**: Start and stop packet capturing on demand through a systemd service that runs a custom bash script.
- **Dynamic IP Filtering**: Selectively capture traffic related to specified IP addresses. Users can dynamically set and modify the capture filter directly from the web interface.
- **Real-Time Status Monitoring**: View the current status of the `tshark` service, including whether it is running or stopped.
- **Capture File Management**: Download captured packet files from the server. The application lists available capture files with relevant details like file size and creation time.
- **Automated Housekeeping**: Scheduled scripts to manage and clean up old capture files, ensuring efficient use of server resources.
- **Robust Logging**: Comprehensive logging capabilities for both the application and the underlying packet capturing service.
- **Secure Access**: Implementations for secure HTTPS connections and user authentication to ensure controlled and secure access to the application.

![Logged In Screenshot](https://github.com/clutch2sft/rtshark-deployment/blob/main/screenshots/loggedin.png)

### How it Works

`rtshark-app` integrates several components to deliver its functionality:

- A Flask web application serves as the front end, allowing users to interact with the system.
- The back end leverages `tshark` for packet capturing, controlled through a systemd service for reliability and ease of management.
- Bash scripts are used for configuring network settings and managing packet capture files.
- The application uses supervisor for process control, ensuring the Flask app is continuously running and starting automatically on boot.
- Nginx is configured as a reverse proxy, providing secure HTTPS access to the application.

Overall, `rtshark-app` is designed to be a reliable and user-friendly tool for network administrators and IT professionals, providing critical insights into network traffic and aiding in troubleshooting and analysis.

---


---

## Configuration Files and Their Locations

`rtshark-app` uses a couple of key configuration files that dictate its behavior and settings. These files are located in different parts of the repository and are deployed to specific locations on the target device during the setup process. Understanding these files and their functions is crucial for customizing and managing the application effectively.

### 1. rtshark_conf.ini
- **Repository Location**: `roles/flask-app-deployment/config/rtshark_conf.ini`
- **Purpose**: This INI file is the primary configuration file for the Flask application. It includes settings related to the web interface and network monitoring functionality. The file contains various parameters that you can customize, such as IP addresses for packet filtering, user interface options, and other application-specific settings. 
- **Deployment**: During deployment, this file is placed in a directory accessible by the Flask app, allowing it to read and apply the specified configurations.

### 2. rtshark-scripts-settings.inc
- **Repository Location**: `roles/scripts-setup/files/rtshark-scripts-settings.inc`
- **Purpose**: This file is an include (inc) file containing common settings and variables used across various scripts in `rtshark-app`. It typically includes environment variables, logging settings, network interface configurations, and other script-level parameters. By centralizing these settings, it ensures consistency across all the scripts and simplifies the process of making changes to script behaviors.
- **Deployment**: This file is placed in a directory (/usr/local/bin) where it can be sourced by the bash scripts used for network monitoring, packet capturing, and other system-level operations. The scripts refer to this file for necessary configuration values, ensuring that they operate with the desired settings.

---

These configuration files are integral to the flexibility and functionality of `rtshark-app`, allowing for easy customization and management of both the application and the underlying scripts. Modifying these files enables users to tailor the application to their specific network environments and use cases.


---

## How to Deploy rtshark-app

This guide outlines the deployment process of the `rtshark-app` on an Orange Pi R1 Plus device running Ubuntu 20.04.6 (Codename: focal). This deployment is performed remotely from another PC using Ansible. It is assumed that you have already set up your Orange Pi device with the necessary operating system and it is ready for SSH connections.

**Note**: This deployment process has been tested on the Orange Pi R1 Plus. If you are using a different device or OS version, some steps may vary.

### Prerequisites
- An Orange Pi R1 Plus device with Ubuntu 20.04.6 installed and accessible via SSH.
- A PC with Ansible installed, from which the deployment will be performed.
- Basic familiarity with Ansible, SSH, and Linux command line.

### Deployment Steps

1. **Prepare Your Hosts File**:
   On your PC (the one running Ansible), create or edit the `hosts` file within the Ansible directory to include the IP address of your Orange Pi device. This file tells Ansible where to deploy the application.

   Example `hosts` file entry:
   ```ini
   [opi_devices]
   orange_pi_ip ansible_user=your_ssh_user ansible_ssh_private_key_file=/path/to/your/private/key
   ```

2. **Clone the Repository**:
   Clone the `rtshark-app` GitHub repository to your PC.

   ```bash
   git clone https://github.com/clutch2sft/rtshark-deployment.git
   cd rtshark-deployent
   ```

3. **Configure Secrets**:
   Edit the `secrets.yml` file in the repository to define the `admin_password`. This file contains sensitive information and will be encrypted with Ansible Vault.

   ```yaml
   admin_password: "your_strong_password"
   ```

   Encrypt the `secrets.yml` file using Ansible Vault:

   ```bash
   ansible-vault encrypt secrets.yml
   ```

4. **Run Ansible Playbook**:
   Execute the Ansible playbook to deploy the `rtshark-app` on your Orange Pi device. The playbook will handle environment setup, dependency installation, configuration, and starting the application.

   ```bash
   ansible-playbook -i hosts ./playbooks/main.yml --vault-password-file /path/to/vault_password_file
   ```

5. **Verify Deployment**:
   After the playbook finishes, verify that the `rtshark-app` is running correctly on your Orange Pi device. You can do this by checking the status of the services using systemd commands or by accessing the web interface through the device's IP address.

6. **Post-Deployment Configuration (Optional)**:
   You can further customize settings by editing the `rtshark_conf.ini` file and other configurations as necessary for your specific network setup.

### Conclusion
With these steps, you should have the `rtshark-app` successfully deployed and running on your Orange Pi R1 Plus. This setup provides a comprehensive network monitoring and packet capturing solution, ideal for troubleshooting and analysis in various network environments.

**Disclaimer**: This guide assumes a certain level of technical proficiency in Ansible and Linux systems. The provided instructions are for guidance and may require adjustments to fit your specific hardware and software configurations.  Additionally, the Ansible deployment process utilizes self-signed SSL certificates. Users are advised to replace these with their own certificates for enhanced security, a process which is beyond the scope of this guide.

---