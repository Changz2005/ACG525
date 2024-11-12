module audio_echo(
    input wire clk,                     // 单一时钟信号
    input wire reset_n,                 // 低电平复位信号
    input wire signed [31:0] data_in,   // 输入音频数据 (32位)
    output wire signed [31:0] data_out  // 输出带延迟的音频数据 (32位)
);

    // 参数配置
    parameter RAM_DEPTH = 16384;         // RAM的深度，决定延迟时间
    parameter ATTENUATION = 1;           // 衰减因子，用于控制输出音量

    // RAM接口信号
    wire signed [31:0] douta;            // RAM的 Port A 输出数据
    wire signed [31:0] doutb;            // RAM的 Port B 输出数据
    reg [14:0] ada;                      // RAM的写地址 (Port A)
    reg [14:0] adb;                      // RAM的读地址 (Port B)
    reg wrea;                            // RAM写使能信号 (Port A)
    reg cea, ceb;                        // 片选信号 (Port A 和 Port B)
    reg signed [31:0] dina;              // RAM写入数据 (Port A)

    // 地址指针
    reg [14:0] write_pointer;            // 写指针 (14位)
    reg [14:0] read_pointer;             // 读指针 (14位)

    // 实例化双端口 RAM，使用同一个时钟 clk
    Gowin_DPB delay_ram (
        .douta(douta),    // RAM的 Port A 输出数据
        .doutb(doutb),    // RAM的 Port B 输出数据
        .clka(clk),       // 写时钟（与读时钟相同）
        .ocea(1'b1),      // Port A 的输出使能，始终使能
        .cea(cea),        // Port A 的片选信号
        .reseta(~reset_n),// 复位信号 (低电平有效)
        .wrea(wrea),      // 写使能信号 (Port A)
        .clkb(clk),       // 读时钟（与写时钟相同）
        .oceb(1'b1),      // Port B 的输出使能，始终使能
        .ceb(ceb),        // Port B 的片选信号
        .resetb(~reset_n),// 复位信号 (低电平有效)
        .wreb(1'b0),      // 读操作时不需要写使能 (Port B)
        .ada(ada),        // 写地址
        .dina(dina),      // 写数据
        .adb(adb),        // 读地址
        .dinb(32'd0)      // 不需要写入数据 (Port B)
    );

    // 写指针控制
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            write_pointer <= 0;
        end else begin
            // 循环更新写指针
            write_pointer <= (write_pointer + 1) % RAM_DEPTH;
        end
    end

    // 读指针控制
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            read_pointer <= RAM_DEPTH / 2; // 初始读指针设为写指针的延迟量
        end else begin
            // 循环更新读指针
            read_pointer <= (read_pointer + 1) % RAM_DEPTH;
        end
    end

    // 写操作控制
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dina <= 0;
            ada <= 0;
            cea <= 0;
            wrea <= 0;
        end else begin
            dina <= data_in;               // 将输入数据写入 RAM
            ada <= write_pointer;          // 设置写地址
            cea <= 1;                      // 启用片选
            wrea <= 1;                     // 启用写使能
        end
    end

    // 读操作控制
    reg signed [31:0] delayed_audio;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            delayed_audio <= 0;
            adb <= 0;
            ceb <= 0;
        end else begin
            adb <= read_pointer;           // 设置读地址
            ceb <= 1;                      // 启用片选
            delayed_audio <= doutb / ATTENUATION;  // 衰减输出数据
        end
    end

    // 输出带延迟的音频数据
    assign data_out = data_in + delayed_audio;

endmodule
