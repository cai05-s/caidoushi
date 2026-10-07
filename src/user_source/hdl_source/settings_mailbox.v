`timescale 1ns/1ps
// Latest-value bundled-data mailbox. Source holds payload until destination ack.
module settings_mailbox #(parameter WIDTH=64)(
    input wire src_clk,src_rst_n,dst_clk,dst_rst_n,
    input wire [WIDTH-1:0] src_data,
    input wire dst_accept,
    output reg [WIDTH-1:0] dst_data,
    output reg dst_update
);
    wire reset_request_n=src_rst_n && dst_rst_n;
    wire srst_n,drst_n;
    reset_sync u_src_reset(.clk(src_clk),.ext_rst_n(reset_request_n),.rst_n_sync(srst_n));
    reset_sync u_dst_reset(.clk(dst_clk),.ext_rst_n(reset_request_n),.rst_n_sync(drst_n));
    reg [WIDTH-1:0] held_data;
    reg request_toggle,ack_toggle,sent_once;
    (* async_reg="true" *) reg [2:0] ack_sync,request_sync;
    always @(posedge src_clk or negedge srst_n) begin
        if(!srst_n) begin held_data<=0;request_toggle<=0;sent_once<=0;ack_sync<=0;end
        else begin
            ack_sync<={ack_sync[1:0],ack_toggle};
            if(request_toggle==ack_sync[2] && (!sent_once || src_data!=held_data)) begin
                held_data<=src_data;request_toggle<=~request_toggle;sent_once<=1;
            end
        end
    end
    always @(posedge dst_clk or negedge drst_n) begin
        if(!drst_n) begin request_sync<=0;ack_toggle<=0;dst_data<=0;dst_update<=0;end
        else begin
            request_sync<={request_sync[1:0],request_toggle};dst_update<=0;
            if(dst_accept && request_sync[2]!=ack_toggle) begin
                dst_data<=held_data;ack_toggle<=request_sync[2];dst_update<=1;
            end
        end
    end
endmodule
