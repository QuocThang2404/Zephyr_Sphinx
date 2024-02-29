Thread
+++++++++++++++++++++++++++++++++++++++++++++
.. contents::
    :local:
    :depth: 2

Overview
==================

- **Kernel Services:** Zephyr cung cấp các chức năng để quản lý luồng, bao gồm tạo, lập lịch và xóa. 

- **Thread:** Là một đối tượng trong kernel được sử dụng để xử lý các tác vụ ứng dụng phức tạp hoặc mất nhiều thời gian, vượt quá khả năng của bộ xử lý ngắt (ISR). 

- **Số lượng thread:** Ứng dụng có thể tạo ra bất kỳ số lượng thread nào, chỉ giới hạn bởi dung lượng RAM khả dụng. 

- **Mã định danh thread:** Mỗi thread được gán một mã định danh duy nhất khi được tạo, giúp tham chiếu và quản lý dễ dàng. 

**Một thread có các thuộc tính chính sau:**

- **Stack area** là vùng bộ nhớ được sử dụng cho stack của thread. Kích thước của vùng stack có thể được điều chỉnh theo nhu cầu thực tế của thread. Zephyr cung cấp các macro đặc biệt để tạo và làm việc với vùng stack này. 

- **Thread control block** là một khối dữ liệu trong kernel chứa các thông tin nội bộ (metadata) về một luồng cụ thể. Mỗi luồng trong Zephyr đều có một TCB duy nhất. TCB trong Zephyr được định nghĩa như một kiểu dữ liệu có tên ``k_thread``. Kiểu dữ liệu này cung cấp cấu trúc và các biến cần thiết để theo dõi trạng thái của luồng, như vị trí ngăn xếp, trạng thái chạy/dừng, thông tin ưu tiên, v.v. 

- **Entry point function** là hàm khởi động khi luồng bắt đầu chạy. Có thể nhận tối đa 3 giá trị đối số truyền vào. Hàm này chịu trách nhiệm thực hiện các tác vụ của luồng, cấu trúc và nội dung của hàm phụ thuộc vào yêu cầu của từng ứng dụng. 

- **Scheduling priority** hay còn gọi là mức ưu tiên lập lịch được sử dụng để hướng dẫn bộ lập lịch của kernel cách phân bổ thời gian CPU cho luồng. 

- **Thread options** cho phép luồng nhận được sự xử lý đặc biệt của kernel trong các trường hợp cụ thể  giúp nâng cao khả năng kiểm soát và linh hoạt của luồng. 

- **Start delay**: chỉ định khoảng thời gian kernel phải đợi trước khi bắt đầu luồng.

- **Execution mode** có 2 chế độ: supervisor và user. Ở chế độ user thì bị hạn chế một số đặc quyền. Mức độ hạn chế tùy thuộc vào tùy chọn ``CONFIG_USERSPACE``. Chế độ này giúp tăng cường bảo mật và độ ổn định, vì lỗi trong luồng ít ảnh hưởng đến toàn hệ thống. Chế độ supervisor là chế độ mặc định của luồng và cho phép luồng truy cập tất cả quyền hạn:

 - Các lệnh CPU đặc quyền (ví dụ: tắt/bật ngắt).  
 - Toàn bộ không gian địa chỉ nhớ. 
 - Các thiết bị ngoại vi (peripherals). 
 - Do quyền hạn cao, chế độ này tiềm ẩn rủi ro cao nếu xảy ra lỗi trong luồng. 

Lifecylce
==================

Thread Creation
---------------
Một thread phải được tạo trước khi sử dụng. Kernel sẽ khởi tạo khối điều khiển luồng (TCB) và phần này là mỏ đầu của thread’s stack. Phần còn lại của thread’s stack thường chưa được khởi tạo. 
Có 2 hai cách khởi động một luồng (thread) trong Zephyr:  

- Khi xác định **start delay** là ``K_NO_WAIT``, kernel sẽ bắt đầu thực thi luồng ngay lập tức. 
- Có thể yêu cầu kernel trì hoãn thực thi luồng trong một khoảng thời gian nhất định. Điều này được thực hiện bằng cách xác định một giá trị thời gian chờ cho **start delay**. 

Zephyr cho phép hủy bỏ việc trì hoãn khởi động của một luồng trước khi nó bắt đầu chạy. Yêu cầu hủy bỏ chỉ có hiệu lực nếu luồng chưa bắt đầu thực thi.


Thread Termination (Chuaw xong)
---------------
Thông thường, sau khi được khởi động, một luồng sẽ tiếp tục chạy mãi mãi. Tuy nhiên, luồng có thể kết thúc thực thi theo cách *kết thúc đồng bộ (synchronous termination)*. Lúc này luồng trả về từ hàm điểm vào (entry point function), sau đó luồng giải phóng các tài nguyên nó đang sử dụng và biến mất khỏi hệ thống. Đây gọi là **termination**.

Khi luồng kết thúc, nó có trách nhiệm giải phóng mọi tài nguyên được chia sẻ mà nó sở hữu (chẳng hạn như các mutex và bộ nhớ được cấp phát động), vì kernel không tự động lấy lại chúng. 

Trong một số trường hợp, một luồng có thể sleep cho đến khi một luồng khác kết thúc. Điều này có thể được thực hiện bằng API ``k_thread_join()``.  

Thread Aborting
---------------
Một luồng có thể kết thúc quá trình thực thi của nó bằng cách hủy bỏ. Kernel tự động hủy bỏ nếu luồng đó gặp tình trạng lỗi nghiêm trọng, chẳng hạn như **Dereferencing a null pointer**.

- Dereferencing a null pointer là hành động truy cập giá trị tại địa chỉ bộ nhớ và được trỏ bởi một con trỏ null. Con trỏ null là một con trỏ không trỏ đến bất kỳ địa chỉ bộ nhớ nào hợp lệ. 

Một luồng cũng có thể bị hủy bỏ bởi một luồng khác (hoặc bởi chính nó) bằng cách gọi ``k_thread_abort()``. Điều này khiến luồng dừng ngay lập tức bất kể trạng thái hiện tại và bất kỳ công việc đang thực hiện nào. Tuy nhiên, sử dụng ``k_thread_abort()`` nên cẩn thận vì nó có thể dẫn đến hành vi không mong muốn nếu luồng đã thực hiện một số tác vụ nhất định, như đang giữ tài nguyên hoặc đang ở giữa hoạt động quan trọng. Thay vì hủy luồng đột ngột, khuyến khích sử dụng tín hiệu để yêu cầu luồng tự kết thúc theo cách hợp lý. Điều này cho phép luồng dọn dẹp tài nguyên, hoàn thành các tác vụ đang dang dở và chấm dứt một cách sạch sẽ.

Giống với Thread Termination, kernel cũng không thể thu hồi lại các tài nguyên mà Thread đó sử dụng.

Thread Suspension
-----------------
Một luồng có thể bị ngăn không cho thực thi trong một khoảng thời gian vô hạn nếu luồng bị suspended. Hàm ``k_thread_suspend()`` có thể được sử dụng để tạm dừng bất kỳ luồng nào, bao gồm cả luồng đang gọi. Tạm dừng một luồng đã tạm dừng thì không có tác dụng gì. 

Sau khi bị tạm dừng, luồng đó không thể được lên lịch cho đến khi một luồng khác gọi ``k_thread_resume()`` để xóa việc tạm dừng.

.. note::
    Một luồng có thể ngăn chính nó thực thi trong một khoảng thời gian nhất định bằng cách sử dụng ``k_sleep()``. Tuy nhiên, điều này khác với việc tạm dừng một luồng vì một luồng sử dụng ``k_sleep()`` sẽ tự động được thực thi khi đạt đến giới hạn thời gian.

Thread State
-----------------