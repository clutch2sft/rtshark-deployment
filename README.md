rtshark-app

TODO:

Add addtional auth methods to the app to remove static authentication passwords
Allow capture interface selection
Allow online edit of filter ip's
Address the option to not install a bridge when you want capture on a stick


I developed rtshark-app with the specific purpose of facilitating on-site network diagnostics and remote monitoring, particularly for scenarios requiring a portable and deployable packet capture solution. This application is optimized for devices like the Orange Pi R1 and Raspberry Pi, which are ideal for situations where a compact, yet capable, network analysis tool is necessary.

A key feature of rtshark-app is its ability to create a bridge interface that combines two Ethernet interfaces. This functionality allows the device to act as an Ethernet tap, seamlessly integrating into a network for efficient packet capturing. This design choice caters to the needs of network troubleshooting, especially in mobile setups or environments where leaving a dedicated network monitoring device is required.

rtshark-app is a comprehensive network monitoring solution designed to facilitate real-time packet capturing and analysis on network interfaces. Built on top of the powerful tshark utility, this Flask-based web application offers a user-friendly interface for managing and monitoring network traffic. Key features include starting and stopping packet capture, setting filters for specific IP addresses, and downloading captured packets for in-depth analysis.

Key Features
Web Interface: A Flask-based web application providing a simple and intuitive user interface.
Packet Capture Control: Start and stop packet capturing on demand through a systemd service that runs a custom bash script.

Dynamic IP Filtering: Selectively capture traffic related to specified IP addresses. Users can dynamically set and modify the capture filter directly from the web interface.
Real-Time Status Monitoring: View the current status of the tshark service, including whether it is running or stopped.

Capture File Management: Download captured packet files from the server. The application lists available capture files with relevant details like file size and creation time.

Automated Housekeeping: Scheduled scripts to manage and clean up old capture files, ensuring efficient use of server resources.

Robust Logging: Comprehensive logging capabilities for both the application and the underlying packet capturing service.

Secure Access: Implementations for secure HTTPS connections and user authentication to ensure controlled and secure access to the application.

How it Works
rtshark-app integrates several components to deliver its functionality:

A Flask web application serves as the front end, allowing users to interact with the system.
The back end leverages tshark for packet capturing, controlled through a systemd service for reliability and ease of management.

Bash scripts are used for configuring network settings and managing packet capture files.
The application uses supervisor for process control, ensuring the Flask app is continuously running and starting automatically on boot.

Nginx is configured as a reverse proxy, providing secure HTTPS access to the application.
Overall, rtshark-app is designed to be a reliable and user-friendly tool for network administrators and IT professionals, providing critical insights into network traffic and aiding in troubleshooting and analysis.


Configuration Files and Their Locations
rtshark-app uses a couple of key configuration files that dictate its behavior and settings. These files are located in different parts of the repository and are deployed to specific locations on the target device during the setup process. Understanding these files and their functions is crucial for customizing and managing the application effectively.

1. rtshark_conf.ini
Repository Location: roles/flask-app-deployment/config/rtshark_conf.ini
Purpose: This INI file is the primary configuration file for the Flask application. It includes settings related to the web interface and network monitoring functionality. The file contains various parameters that you can customize, such as IP addresses for packet filtering, user interface options, and other application-specific settings.
Deployment: During deployment, this file is placed in a directory (.config) accessible by the Flask app, allowing it to read and apply the specified configurations.

2. rtshark-scripts-settings.inc
Repository Location: roles/scripts-setup/files/rtshark-scripts-settings.inc
Purpose: This file is an include (inc) file containing common settings and variables used across various scripts in rtshark-app. It typically includes environment variables, logging settings, network interface configurations, and other script-level parameters. By centralizing these settings, it ensures consistency across all the scripts and simplifies the process of making changes to script behaviors.

Deployment: This file is placed in a directory (/usr/local/bin) where it can be sourced by the bash scripts used for network monitoring, packet capturing, and other system-level operations. The scripts refer to this file for necessary configuration values, ensuring that they operate with the desired settings.
These configuration files are integral to the flexibility and functionality of rtshark-app, allowing for easy customization and management of both the application and the underlying scripts. Modifying these files enables users to tailor the application to their specific network environments and use cases.
