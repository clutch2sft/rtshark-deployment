rtshark-app

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



TODO:

Add addtional auth methods to the app to remove static authentication passwords
Allow capture interface selection
Allow online edit of filter ip's
Address the option to not install a bridge when you want capture on a stick



