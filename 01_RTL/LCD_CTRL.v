module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;


//-------coding--------
reg [4:0] next_state;
reg [4:0] current_state;

reg [7:0] data [0:63];
reg [9:0] data_reg;
integer data_i;
reg [5:0] address_reg;
reg [2:0] coord_x,coord_y;
wire [5:0] tpl,tpr,btl,btr;

assign tpl = {coord_y - 3'b1,coord_x - 3'b1};
assign tpr = {coord_y - 3'b1,coord_x};
assign btl = {coord_y,coord_x - 3'b1};
assign btr = {coord_y,coord_x};

parameter address_max = 6'd63;

parameter IDLE     = 5'd0;
parameter IROM_RD = 5'd1;
parameter WAIT_CMD = 5'd2;
parameter WRITE    = 5'd3;
parameter SHIFT_UP = 5'd4;
parameter SHIFT_DOWN = 5'd5;
parameter SHIFT_LEFT = 5'd6;
parameter SHIFT_RIGHT = 5'd7;
parameter MAX = 5'd8;
parameter MIN = 5'd9;
parameter AVERAGE = 5'd10;
parameter CCWROTATION = 5'd11;
parameter CWROTATION  = 5'd12;
parameter MIRROR_X = 5'd13;
parameter MIRROR_Y = 5'd14;
parameter IRAM_VALID = 5'd15;
parameter DONE = 5'd16;


//current_state
always @(posedge clk or posedge reset) begin
    if (reset) current_state <= IDLE;
    else current_state <= next_state;
    //$display("%d,%d,%d,%d,%d\n",data[tpl],data[tpr],data[btl],data[btr],next_state);
end

//next_state
always @(*) begin
    case (current_state)
        IDLE: next_state = IROM_rd ? IROM_RD : current_state;
        IROM_RD : next_state = (IROM_rd == 1'b0) ? WAIT_CMD : current_state;
        WAIT_CMD : begin
            if(cmd_valid == 1'b1)begin
                if(cmd == 4'b0000) next_state = WRITE;
                else if (cmd == 4'b0001) next_state = SHIFT_UP;
                else if (cmd == 4'b0010) next_state = SHIFT_DOWN;
                else if (cmd == 4'b0011) next_state = SHIFT_LEFT;
                else if (cmd == 4'b0100) next_state = SHIFT_RIGHT;
                else if (cmd == 4'b0101) next_state = MAX;
                else if (cmd == 4'b0110) next_state = MIN;
                else if (cmd == 4'b0111) next_state = AVERAGE;
                else if (cmd == 4'b1000) next_state = CCWROTATION;
                else if (cmd == 4'b1001) next_state = CWROTATION;
                else if (cmd == 4'b1010) next_state = MIRROR_X;
                else if (cmd == 4'b1011) next_state = MIRROR_Y;
                else next_state = current_state;
            end
            else next_state = current_state;
        end
        SHIFT_UP : next_state = WAIT_CMD;
        SHIFT_DOWN : next_state = WAIT_CMD;
        SHIFT_LEFT : next_state = WAIT_CMD;
        SHIFT_RIGHT : next_state = WAIT_CMD;
        MAX : next_state = WAIT_CMD;
        MIN : next_state = WAIT_CMD;
        AVERAGE : next_state = WAIT_CMD;
        CCWROTATION : next_state = WAIT_CMD;
        CWROTATION : next_state = WAIT_CMD;
        MIRROR_X : next_state = WAIT_CMD;
        MIRROR_Y : next_state = WAIT_CMD;
        WRITE : next_state = (IRAM_A == 6'd63) ? DONE : current_state;
        default: next_state = current_state;
    endcase
end

//IROM_rd
always @(posedge clk or posedge reset) begin
    if(reset) IROM_rd <= 1;
    else if(IROM_A == 6'd63) IROM_rd <= 0;
    else IROM_rd <= IROM_rd;
end

//IROM_A
always @(posedge clk or posedge reset) begin
    if(reset) IROM_A <= 6'd0;
    else if(current_state == IROM_RD && IROM_A < 6'd63) IROM_A <= IROM_A + 6'd1;
end

//busy
always @(posedge clk or posedge reset) begin
    if(reset) busy <= 1'b1;
    else if(next_state == WAIT_CMD || next_state == DONE) busy <= 1'b0;
    else if(cmd_valid == 1'b1) busy <= 1'b1;
    else busy <= busy;
end

//coord_x
always @(posedge clk or posedge reset) begin
    if(reset) coord_x <= 3'd4;
    else if(current_state == SHIFT_LEFT && coord_x > 3'd1) coord_x <= coord_x - 3'd1;
    else if(current_state == SHIFT_RIGHT && coord_x < 3'd7) coord_x <= coord_x + 3'd1;
end
//coord_y
always @(posedge clk or posedge reset) begin
    if(reset) coord_y <= 3'd4;
    else if(current_state == SHIFT_UP && coord_y > 3'd1) coord_y <= coord_y - 3'd1;
    else if(current_state == SHIFT_DOWN && coord_y < 3'd7) coord_y <= coord_y + 3'd1;
end

//address_reg
always @(posedge clk or posedge reset) begin
    if(reset) address_reg <= 6'd0;
    else if(current_state == WRITE) address_reg <= address_reg + 6'd1;
end

//IRAM_valid
always @(posedge clk or posedge reset) begin
    if(reset)IRAM_valid <= 1'b0;
    else if(current_state == WRITE) IRAM_valid <= 1'b1;
    else if(current_state == DONE) IRAM_valid <= 1'b0;
end

//IRAM_A
always @(posedge clk or posedge reset) begin
    if(reset) IRAM_A <= 6'd0;
    else if(current_state == WRITE) IRAM_A <= address_reg;
    else IRAM_A <= IRAM_A;
end

//IRAM_D
always @(posedge clk or posedge reset) begin
    if(reset) IRAM_D <= 8'd0;
    else if(current_state == WRITE) IRAM_D <= data[address_reg];
end

//done
always @(posedge clk or posedge reset) begin
    if(reset) done <= 1'b0;
    else if(current_state == DONE) done <= 1'b1;
    else done <= done;
end
//data_reg
always @(*) begin
    if(reset) data_reg = 10'd0;
    else if (current_state == MAX)begin
        if(data[tpl] >= data[tpr] && data[tpl] >= data[btl] && data[tpl] >= data[btr])begin
            data_reg = data[tpl];
        end
        else if(data[tpr] >= data[tpl] && data[tpr] >= data[btl] && data[tpr] >= data[btr])begin
            data_reg = data[tpr];
        end
        else if(data[btl] >= data[tpr] && data[btl] >= data[tpl] && data[btl] >= data[btr])begin
             data_reg = data[btl];
        end
        else if(data[btr] >= data[tpr] && data[btr] >= data[tpl] && data[btr] >= data[btl])begin
            data_reg = data[btr];
        end
    end
    else if (current_state == MIN)begin
        if(data[tpl] <= data[tpr] && data[tpl] <= data[btl] && data[tpl] <= data[btr])begin
            data_reg = data[tpl];
        end
        else if(data[tpr] <= data[tpl] && data[tpr] <= data[btl] && data[tpr] <= data[btr])begin
            data_reg = data[tpr];
        end
        else if(data[btl] <= data[tpl] && data[btl] <= data[tpr] && data[btl] <= data[btr])begin
            data_reg = data[btl];
        end
        else if(data[btr] <= data[tpl] && data[btr] <= data[tpr] && data[btr] <= data[btl])begin
            data_reg = data[btr];
        end
    end
    else if (current_state == AVERAGE)begin
        data_reg = (data[tpl] + data[tpr] + data[btl] + data[btr]) >> 2;
    end
    else data_reg = data_reg;
end
//data
always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (data_i = 0;data_i <= address_max;data_i = data_i + 6'd1) begin
            data[data_i] <= 8'd0;
        end
    end
    else if(current_state == IROM_RD) begin
        data[IROM_A] <= IROM_Q;
    end
    else if (current_state == MAX)begin
        data[tpl] <= data_reg;
        data[tpr] <= data_reg;
        data[btl] <= data_reg;
        data[btr] <= data_reg;
    end
    else if (current_state == MIN)begin
        data[tpl] <= data_reg;
        data[tpr] <= data_reg;
        data[btl] <= data_reg;
        data[btr] <= data_reg;
    end
    else if (current_state == AVERAGE)begin
        data[tpl] <= data_reg;
        data[tpr] <= data_reg;
        data[btl] <= data_reg;
        data[btr] <= data_reg;
    end
    else if (current_state == CCWROTATION)begin
        data[tpl] <= data[tpr];
        data[tpr] <= data[btr];
        data[btr] <= data[btl];
        data[btl] <= data[tpl];
    end
    else if (current_state == CWROTATION)begin
        data[tpl] <= data[btl];
        data[tpr] <= data[tpl];
        data[btr] <= data[tpr];
        data[btl] <= data[btr];
    end
    else if (current_state == MIRROR_X)begin
        data[tpl] <= data[btl];
        data[tpr] <= data[btr];
        data[btr] <= data[tpr];
        data[btl] <= data[tpl];
    end
    else if (current_state == MIRROR_Y)begin
        data[tpl] <= data[tpr];
        data[tpr] <= data[tpl];
        data[btr] <= data[btl];
        data[btl] <= data[btr];
    end
end
endmodule