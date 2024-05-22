## 部分参数说明

- `input_format_allow_errors_num` 跳过解析错误的最大行数
- `input_format_allow_errors_ratio` 跳过解析错误的行数占总行数的比列  
以上两个配置同时使用，错误数大于 `errors_num` 且占比大于 `errors_ratio` 时，不再跳过解析错误。  
跳过以row为单位，即：一个kafka message内的某行出错，则只跳过该行

- `kafka_skip_broken_messages` 与 `input_format_allow_errors_num` 含义相同
- `kafka_handle_error_mode` 可设置为 'default' 或 'stream'。若设置为 'stream'，
    - 错误消息和异常信息会计入`_raw_message`和`_error`虚拟列，使用物化视图可将虚拟列转储在本地表中
    - 同时会在kafka转储的目标表新增一行默认值行（脏数据）
    - 错误以message为单位，即：一个kafka message内的某行出错，则整个message计入虚拟列
    - 若同时设置 `kafka_skip_broken_messages`，则优先执行跳过逻辑，达到上限后，将错误计入虚拟列
