module spiclkgen(input clk
    , input rst
    ,   output reg clk_dvd
    ,   output reg shifted
    , output reg mreset
);

    reg [3:0] cntr;
    
    wire [1:0] cnt;
    
    assign cnt = cntr[1:0];

    
    always @(posedge clk) begin
        if (~rst) begin
            cntr <= cntr + 1;
            if (cnt == 0) begin
                clk_dvd <= ~clk_dvd;
            end
            if (cnt == 1) begin
                shifted <= ~shifted;
            end
            if (cntr == 15) begin
                mreset <= 0;
            end
        end else begin
            cntr <= 0;
            clk_dvd <= 0;
            shifted <= 1;
            mreset <= 1;
        end
    end
    
endmodule

module linespitransmitter(input clk
    , input rst
    , input [ADD_WIDTH:0] pixel_count
    , input [32:0] pixel
    , output [ADD_WIDTH - 1:0] address
    , output out
    , output done);
    
    parameter ADD_WIDTH = 8;
    
    localparam RESET = 4'b1xxx
    , FRAME_OPENING = 4'b0100
    , DATA_SENDING = 4'b0110
    , FRAME_CLOSE = 4'b0101
    , SESSION_DONE = 4'b0111;
    
    reg metada_sent;
    reg data_sent;
    
    reg [31:0] pixel_reg;
    reg [31:0] outgoing_pixel_reg;
    reg [4:0] bits_sent;
    reg pixel_ack;
    reg pixel_need_ack;
    reg done_reg;
    
    reg [ADD_WIDTH:0] address_reg;
    reg [ADD_WIDTH:0] sent_cnt;
    
    wire [3:0] state;
    assign state = {rst, bits_sent == 30, metada_sent, data_sent};
    assign address = address_reg[ADD_WIDTH - 1:0];
    assign out = outgoing_pixel_reg[31];
    assign done = done_reg;
    
    always @(posedge clk) begin
        
    end
    
    always @(posedge clk) begin

		if (~rst) begin
            bits_sent <= bits_sent + 1;
            if (bits_sent == 29) begin
                pixel_ack <= 1;
                sent_cnt <= sent_cnt + 1;
                if (~data_sent) begin
                    address_reg <= address_reg + 1;
                end
            end        
            if (pixel_need_ack) begin
                outgoing_pixel_reg <= pixel_reg;
                pixel_need_ack <= 0;
            end else begin
                outgoing_pixel_reg <= {outgoing_pixel_reg[30:0], outgoing_pixel_reg[31]};
                
            end            
        
        end
    
        casex (state)
            RESET: begin
                pixel_reg <= 0;
                outgoing_pixel_reg <= 0;
                pixel_ack <= 0;
                address_reg <= 0;
                sent_cnt <= 0;
                metada_sent <= 0;
                data_sent <= 0;
                bits_sent <= 0;
                pixel_need_ack <= 1;
                done_reg <= 0;
            end
            FRAME_OPENING: begin                
                if (pixel_ack) begin
                    sent_cnt <= 0;
                    metada_sent <= 1;
                    pixel_reg <= pixel;
                    pixel_need_ack <= 1;
                    pixel_ack <= 0;
                end
            end
            DATA_SENDING: begin                
                if (pixel_ack) begin                                        
                    pixel_need_ack <= 1;
                    pixel_ack <= 0;
                    if (sent_cnt == pixel_count) begin
                        metada_sent <= 0;
                        data_sent <= 1;
                        pixel_reg <= 32'hFFFFFFFF;
                    end else begin
                        pixel_reg <= pixel;                        
                    end
                end
                if (sent_cnt == pixel_count) begin
                    metada_sent <= 0;
                    data_sent <= 1;
                end
                pixel_ack <= 0;
            end
            FRAME_CLOSE: begin                
                if (pixel_ack) begin
                    metada_sent <= 1;
						  done_reg <= 1;
                end
            end
        endcase
    end
    

endmodule
