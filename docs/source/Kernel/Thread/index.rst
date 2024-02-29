Thread
+++++++++++++++++++++++++++++++++++++++++++++
.. contents::
    :local:
    :depth: 2

Overview
======================================

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
============================

Thread Creation
---------------
Một thread phải được tạo trước khi sử dụng. Kernel sẽ khởi tạo khối điều khiển luồng (TCB) và phần này là mỏ đầu của thread’s stack. Phần còn lại của thread’s stack thường chưa được khởi tạo. 
Có 2 hai cách khởi động một luồng (thread) trong Zephyr:  

- Khi xác định **start delay** là ``K_NO_WAIT``, kernel sẽ bắt đầu thực thi luồng ngay lập tức. 
- Có thể yêu cầu kernel trì hoãn thực thi luồng trong một khoảng thời gian nhất định. Điều này được thực hiện bằng cách xác định một giá trị thời gian chờ cho **start delay**. 

Zephyr cho phép hủy bỏ việc trì hoãn khởi động của một luồng trước khi nó bắt đầu chạy. Yêu cầu hủy bỏ chỉ có hiệu lực nếu luồng chưa bắt đầu thực thi.


Thread Termination (Chuaw xong)
---------------------------------
Thông thường, sau khi được khởi động, một luồng sẽ tiếp tục chạy mãi mãi. Tuy nhiên, luồng có thể kết thúc thực thi theo cách *kết thúc đồng bộ (synchronous termination)*. Lúc này luồng trả về từ hàm điểm vào (entry point function), sau đó luồng giải phóng các tài nguyên nó đang sử dụng và biến mất khỏi hệ thống. Đây gọi là **termination**.

Khi luồng kết thúc, nó có trách nhiệm giải phóng mọi tài nguyên được chia sẻ mà nó sở hữu (chẳng hạn như các mutex và bộ nhớ được cấp phát động), vì kernel không tự động lấy lại chúng. 

Trong một số trường hợp, một luồng có thể sleep cho đến khi một luồng khác kết thúc. Điều này có thể được thực hiện bằng API ``k_thread_join()``.  

Thread Aborting
---------------------
Một luồng có thể kết thúc quá trình thực thi của nó bằng cách hủy bỏ. Kernel tự động hủy bỏ nếu luồng đó gặp tình trạng lỗi nghiêm trọng, chẳng hạn như **Dereferencing a null pointer**.

- Dereferencing a null pointer là hành động truy cập giá trị tại địa chỉ bộ nhớ và được trỏ bởi một con trỏ null. Con trỏ null là một con trỏ không trỏ đến bất kỳ địa chỉ bộ nhớ nào hợp lệ. 

Một luồng cũng có thể bị hủy bỏ bởi một luồng khác (hoặc bởi chính nó) bằng cách gọi ``k_thread_abort()``. Điều này khiến luồng dừng ngay lập tức bất kể trạng thái hiện tại và bất kỳ công việc đang thực hiện nào. Tuy nhiên, sử dụng ``k_thread_abort()`` nên cẩn thận vì nó có thể dẫn đến hành vi không mong muốn nếu luồng đã thực hiện một số tác vụ nhất định, như đang giữ tài nguyên hoặc đang ở giữa hoạt động quan trọng. Thay vì hủy luồng đột ngột, khuyến khích sử dụng tín hiệu để yêu cầu luồng tự kết thúc theo cách hợp lý. Điều này cho phép luồng dọn dẹp tài nguyên, hoàn thành các tác vụ đang dang dở và chấm dứt một cách sạch sẽ.

Giống với Thread Termination, kernel cũng không thể thu hồi lại các tài nguyên mà Thread đó sử dụng.

Thread Suspension
---------------------
Một luồng có thể bị ngăn không cho thực thi trong một khoảng thời gian vô hạn nếu luồng bị suspended. Hàm ``k_thread_suspend()`` có thể được sử dụng để tạm dừng bất kỳ luồng nào, bao gồm cả luồng đang gọi. Tạm dừng một luồng đã tạm dừng thì không có tác dụng gì. 

Sau khi bị tạm dừng, luồng đó không thể được lên lịch cho đến khi một luồng khác gọi ``k_thread_resume()`` để xóa việc tạm dừng.

.. note::
    Một luồng có thể ngăn chính nó thực thi trong một khoảng thời gian nhất định bằng cách sử dụng ``k_sleep()``. Tuy nhiên, điều này khác với việc tạm dừng một luồng vì một luồng sử dụng ``k_sleep()`` sẽ tự động được thực thi khi đạt đến giới hạn thời gian.

Thread State
-----------------
Một luồng không có yếu tố ngăn cản việc thực thi nó được coi là **sẵn sàng (ready)** và đủ điều kiện để được chọn làm **luồng hiện tại**. 

Một luồng có một hoặc nhiều yếu tố ngăn cản việc thực thi nó được coi là **chưa sẵn sàng (unready)** và không thể được chọn làm luồng hiện tại. 

Các yếu tố sau làm cho luồng chưa sẵn sàng: 

- Luồng chưa được bắt đầu.
- Thread đang chờ kernel thưc hiện xong một hoạt động. 

 - Khi một luồng yêu cầu sử dụng một kernel object (ví dụ như lấy một semaphore), nhưng đối tượng đó chưa sẵn sàng (ví dụ như semaphore đã được chiếm bởi một luồng khác), luồng sẽ bị chặn và chờ đợi cho đến khi thao tác trên đối tượng hoàn thành.

- Luồng đang chờ thời gian để thực thi (hết thời gian chờ). 
- Luồng bị chặn (suspended).
- Luồng bị chấm dứt (terminated) hoặc hủy bỏ (aborted).

.. note:: 
    Sơ đồ có thể khiến bạn nghĩ ``ready`` và ``run`` là hai trạng thái luồng riêng biệt. Thực ra ``ready`` là một trạng thái thực sự của luồng, cho biết nó đã được kích hoạt và đủ điều kiện để chạy. ``Run`` không phải là trạng thái luồng, mà là **trạng thái lịch trình**. Trạng thái lịch trình cho biết liệu một luồng có đang được hệ thống thực thi hay không.

Thread Stack Objects 
---------------------------

Mỗi luồng đều có một stack riêng biệt để CPU lưu trữ context (các trạng thái, biến, dữ liệu) của luồng. Tùy thuộc vào cấu hình sẽ có một số yêu cầu ràng buộc: 

- Có thể cần có dự trữ bộ nhớ bổ sung dành riêng cho cấu trúc quản lý bộ nhớ.
- Nếu hệ thống bật chức năng “phát hiện tràn stack ở vùng bảo vệ”, bắt buộc phải có một vùng nhỏ bảo vệ ghi ngay trước vùng đệm stack của mỗi luồng. Nếu luồng cố gắng ghi dữ liệu vào vùng này, nó sẽ gặp lỗi truy cập vi phạm, cho biết stack đã bị tràn. 
- Nếu kích hoạt userspace trong Zephyr thì yêu cầu một stack riêng cố định cho việc xử lý system call. Khi chương trình thực hiện system call, nó sẽ chuyển sang chế độ đặc quyền (privileged mode) và thực hiện một lệnh đặc biệt (special instruction) để yêu cầu dịch vụ từ kernel. 
- Nếu userspace được bật, bộ đệm thread’s stack phải có kích thước phù hợp và được căn chỉnh sao cho vùng bộ nhớ bảo vệ vừa khớp hoàn toàn với vùng stack. 

Các ràng buộc căn chỉnh có thể khá hạn chế, ví dụ: MPU có thể yêu cầu các vùng có kích thước là lũy thừa của 2 (4, 8, 16 byte).

Kernel-only Stacks 
*******************
Nếu ta biết trước thread chỉ chạy trong chế độ kernel, hoặc stack đang được sử dụng cho các bối cảnh đặc biệt như xử lý ngắt thì nên sử dụng các macro ``K_KERNEL_STACK`` để khai báo stack. 

Các stack này tiết kiệm bộ nhớ vì vùng MPU sẽ không bao giờ cần được lập trình để bảo vệ chính bộ đệm của stack và kernel sẽ không cần dự trữ thêm chỗ cho privileged elevation stack hoặc cấu trúc dữ liệu quản lý bộ nhớ vì 2 phần đó chỉ liên quan đến các luồng ở chế độ người dùng. 

.. note:: 
    Macro ``K_KERNEL_STACK`` tối ưu hóa việc sử dụng bộ nhớ bằng cách: 

    - Không cần cấu hình vùng MPU (Memory Protection Unit) cho stack: MPU tự động quản lý quyền truy cập cho kernel’s stack, loại bỏ nhu cầu cấu hình thủ công. 
    - Không cần privileged elevation stack: Kernel’s stack đã có các tính năng cần thiết để xử lý các tác vụ đặc quyền nên không cần thêm stack riêng. 
    - Không cần dữ liệu quản lý bộ nhớ riêng: Kernel’s stack sử dụng chung cấu trúc dữ liệu quản lý bộ nhớ với các stack khác, dẫn đến tiết kiệm bộ nhớ. 

Bất kỳ nỗ lực truy cập kernel’s stack từ chế độ người dùng sẽ dẫn đến lỗi nghiêm trọng. 

Nếu ``CONFIG_USERSPACE`` không được kích hoạt, tập hợp các macro ``K_THREAD_STACK`` sẽ có tác dụng giống hệt với macro ``K_KERNEL_STACK``. 

Thread Stacks  
*******************
Nếu biết rằng stack sẽ cần lưu trữ các luồng của người dùng hoặc nếu không thể xác định được điều này, hãy xác định stack bằng macro K_THREAD_STACK. Điều này có thể sử dụng nhiều bộ nhớ hơn nhưng stack object sẽ phù hợp để lưu trữ các luồng của người dùng. 

Nếu ``CONFIG_USERSPACE`` không được kích hoạt, tập hợp các macro ``K_THREAD_STACK`` sẽ có tác dụng giống hệt với macro ``K_KERNEL_STACK``. 

Thread Priorities
---------------------------
Mức ưu tiên của luồng là một giá trị số nguyên, có thể là âm hoặc không âm. Số nguyên càng thấp thì mức ưu tiên càng cao. Nói cách khác, luồng có giá trị ưu tiên thấp hơn sẽ được hệ điều hành xử lý trước các luồng có giá trị ưu tiên cao hơn. 
Ví dụ
- Thread A có mức ưu tiên là 4
- Thread B có mức ưu tiên là 7
- Thread C có mức ưu tiên là -2

Vậy mức ưu tiên sẽ như sau: C > A > B 

Scheduler phân biệt giữa hai loại luồng, dựa trên mức độ ưu tiên của từng luồng. 

- Cooperative thread: Có mức ưu tiên âm. Một khi trở thành luồng đang chạy, nó sẽ duy trì trạng thái đó cho đến khi tự thực hiện hành động khiến nó không sẵn sàng chạy tiếp (ví dụ như chờ đợi tài nguyên, kết thúc tác vụ). 
- Preemptive thread: Có mức ưu tiên không âm. Một khi trở thành luồng đang chạy, nó có thể bị hệ điều hành tạm dừng bất cứ lúc nào nếu:

 - Một luồng cooperative chuyển sang trạng thái sẵn sàng chạy. 
 - Một luồng khác chiếm quyền với mức ưu tiên cao hơn hoặc bằng nó chuyển sang trạng thái sẵn sàng chạy. 

Mức ưu tiên ban đầu của một luồng có thể được thay đổi lên (tăng quyền ưu tiên) hoặc xuống (giảm quyền ưu tiên) sau khi luồng đó đã được khởi chạy. 

Điều này có nghĩa là preemptive thread có thể trở thành cooperative thread nếu chuyển mức ưu tiên xuống âm, và ngược lại. 

.. note:: 
    Scheduler không tự động thay đổi mức ưu tiên của luồng dựa trên suy đoán mà chỉ thay đổi mức ưu tiên theo yêu cầu của ứng dụng.

Kernel hỗ trợ số lượng mức ưu tiên gần như không giới hạn. Điều này cho phép linh hoạt cao trong việc thiết lập mức ưu tiên phù hợp cho từng luồng. Hai tùy chọn cấu hình ``CONFIG_NUM_COOP_PRIORITIES``  và ``CONFIG_NUM_PREEMPT_PRIORITIES`` xác định số mức ưu tiên cho mỗi loại luồng: 

- Cooperative threads: (- ``CONFIG_NUM_COOP_PRIORITIES``) to -1
- Preemptive threads: 0 to (``CONFIG_NUM_PREEMPT_PRIORITIES`` - 1) 

Ví dụ: cấu hình 5 mức độ ưu tiên cho cooperative và 10 mức độ ưu tiên preemptive sẽ có kết quả lần lượt là trong phạm vi từ -5 đến -1 và 0 đến 9. 