MODBUS
++++++++++++++++++++++++

.. contents::
    :local:
    :depth: 2

Modbus Protocol
==========================
Giao thức Modbus là giao thức yêu cầu-phản hồi được triển khai bằng cách sử dụng mối quan hệ master - slave. Trong mối quan hệ này, giao tiếp luôn diễn ra theo cặp, với thiết bị master khởi tạo yêu cầu và sau đó chờ đợi phản hồi từ thiết bị slave. Thiết bị master sẽ chịu trách nhiệm bắt đầu mọi tương tác. 

- **Thiết bị Master**: Thường là human machine interface (HMI) hoặc hệ thống Supervisory Control and Data Acquisition (SCADA). Chúng sử dụng Modbus để đọc dữ liệu hoặc gửi lệnh cho các thiết bị Slave.
- **Thiết bị Slave:** Là các thiết bị như cảm biến, PLC (bộ điều khiển logic lập trình) hoặc PAC (bộ điều khiển tự động lập trình). Chúng thu thập dữ liệu hoặc thực hiện các hành động dựa trên yêu cầu của thiết bị Master.

.. image:: img/Modbus-Network.png
    :align: center

Các lớp trong giao thức Modbus
=================================
