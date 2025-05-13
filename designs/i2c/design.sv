/* verilator lint_off MULTITOP */
module i2c_slave#(
    ADDR = 7'h55
)(
SCL,
SDA,
RST
);
input RST;//asynchronous reset input
inout SDA, SCL;

parameter [2:0] STATE_IDLE      = 3'h0,//idle
                STATE_DEV_ADDR  = 3'h1,//the slave addr match
                STATE_READ      = 3'h2,//the op=read 
                STATE_IDX_PTR   = 3'h3,//get the index of inner-register
                STATE_WRITE     = 3'h4;//write the data in the reg 


reg             start_detect;
reg             start_resetter;

reg             stop_detect;
reg             stop_resetter;

reg [3:0]       bit_counter;//(from 0 to 8)9counters-> one byte=8bits and one ack=1bit
reg [7:0]       input_shift;
reg             master_ack;
reg [2:0]       state;
reg [7:0]       regs[0:255];//slave_reg
reg [7:0]       output_shift;
reg             output_control;
reg [7:0]       index_pointer;

parameter [6:0] device_address = ADDR;
wire            start_rst = RST | start_resetter;//detect the START for one cycle
wire            stop_rst = RST | stop_resetter;//detect the STOP for one cycle
wire            lsb_bit = (bit_counter == 4'h7) && !start_detect;//the 8bits one byte data
wire            ack_bit = (bit_counter == 4'h8) && !start_detect;//the 9bites ack 
wire            address_detect = (input_shift[7:1] == device_address);//the input address match the slave
wire            read_write_bit = input_shift[0];// the write or read operation 0=write and 1=read
wire            write_strobe = (state == STATE_WRITE) && ack_bit;//write state and finish one byte=8bits
assign          SDA = output_control ? 1'bz : 1'b0;
//---------------------------------------------
//---------------detect the start--------------
//---------------------------------------------
always @ (posedge start_rst or negedge SDA)
begin
        if (start_rst)
                start_detect <= 1'b0;
        else
                start_detect <= SCL;
end

always @ (posedge RST or posedge SCL)
begin
        if (RST)
                start_resetter <= 1'b0;
        else
                start_resetter <= start_detect;
end

//---------------------------------------------
//---------------detect the stop---------------
//---------------------------------------------

always_ff @ (posedge stop_rst or posedge SDA)
begin   
        if (stop_rst)
                stop_detect <= 1'b0;
        else
                stop_detect <= SCL;
end

always_ff @ (posedge RST or posedge SCL)
begin   
        if (RST)
                stop_resetter <= 1'b0;
        else
                stop_resetter <= stop_detect;
end
//the STOP just last for one cycle of SCL
//don't need to check the RESTART,due to: a START before it is STOP,it's START; 
//                                        a START before it is START,it's RESTART;
//the RESET and START combine can be recognise the RESTART,but it's doesn't matter



//---------------------------------------------
//---------------latch the data---------------
//---------------------------------------------
always_ff @ (negedge SCL)
begin
        if (ack_bit || start_detect)
                bit_counter <= 4'h0;
        else
                bit_counter <= bit_counter + 4'h1;
end
//counter to 9(from 0 to 8), one byte=8bits and one ack 
always_ff @ (posedge SCL)
        if (!ack_bit)
                input_shift <= {input_shift[6:0], SDA};
//at posedge SCL the data is stable,the input_shift get one byte=8bits



//---------------------------------------------
//------------slave-to-master transfer---------
//---------------------------------------------
always_ff @ (posedge SCL)
        if (ack_bit)
                master_ack <= ~SDA;//the ack SDA is low
//the 9th bits= ack if the SDA=1'b0 it's a ACK, 



//---------------------------------------------
//------------state machine--------------------
//---------------------------------------------
always_ff @ (posedge RST or negedge SCL)//jcyuan comment
begin
        if (RST)
                state <= STATE_IDLE;
        else if (start_detect)
                state <= STATE_DEV_ADDR;
        else if (ack_bit)//at the 9th cycle and change the state by ACK
        begin
                /* verilator lint_off CASEINCOMPLETE */
                case (state)
                STATE_IDLE:
                        state <= STATE_IDLE;

                STATE_DEV_ADDR:
                        if (!address_detect)//addr don't match
                                state <= STATE_IDLE;
                        else if (read_write_bit)// addr match and operation is read
                                state <= STATE_READ;
                        else//addr match and operation is write
                                state <= STATE_IDX_PTR;

                STATE_READ:
                        if (master_ack)//get the master ack 
                                state <= STATE_READ;
                        else//no master ack ready to STOP
                                state <= STATE_IDLE;

                STATE_IDX_PTR:
                        state <= STATE_WRITE;//get the index and ready to write 

                STATE_WRITE:
                        state <= STATE_WRITE;//when the state is write the state 
                endcase
        end
        //if don't write and master send a stop,need to jump idle
        //the stop_detect is the next cycle of ACK
        else if(stop_detect)//jcyuan add  
                state <= STATE_IDLE;//jcyuan add
end

//---------------------------------------------
//------------Register transfers---------------
//---------------------------------------------

//-------------------for index----------------
always_ff @ (posedge RST or negedge SCL)
begin
        if (RST)
                index_pointer <= 8'h00;
        else if (stop_detect)
                index_pointer <= 8'h00;
        else if (ack_bit)//at the 9th bit -ack, the input_shift has one bytes
        begin
                if (state == STATE_IDX_PTR) //at the state get the inner-register index
                        index_pointer <= input_shift;
        end
end

//----------------for write---------------------------
//we only define 4 registers for operation
always_ff @ (posedge RST or negedge SCL)
begin
        if (RST)
        begin
                for (int i = 0; i < 256 ; i= i+1) begin
                    regs[i] <= 0;
                end

				regs[5] <= 8'hAA;
        end//the moment the input_shift has one byte=8bits
        else begin
            if(write_strobe) begin
                regs[index_pointer] <= input_shift;
            end
        end
end

//------------------------for read-----------------------
always_ff @ (negedge SCL)
begin   
        if (lsb_bit)//at one byte that can be load the output_shift
        begin   
                output_shift <= regs[index_pointer];
        end
        else
                output_shift <= {output_shift[6:0], 1'b0};
                //once the shift it,after 8 times the output_shift=8'b0
                //the 9th bit is 0 for the RESTART for address match slave ACK 
end

//---------------------------------------------
//------------Output driver--------------------
//---------------------------------------------

always_ff @ (posedge RST or negedge SCL)
begin   
        if (RST)
                output_control <= 1'b1;
        else if (start_detect)
                output_control <= 1'b1;
        else if (lsb_bit)
        begin   
                output_control <=
                    !(((state == STATE_DEV_ADDR) && address_detect) ||
                      (state == STATE_IDX_PTR) ||
                      (state == STATE_WRITE)); 
                //when operation is wirte 
                //addr match gen ACK,the index get gen ACK,and write data gen ACK
        end
        else if (ack_bit)
        begin
                // Deliver the first bit of the next slave-to-master
                // transfer, if applicable.
                if (((state == STATE_READ) && master_ack) ||
                    ((state == STATE_DEV_ADDR) &&
                        address_detect && read_write_bit))
                        output_control <= output_shift[7];
                        //for the RESTART and send the addr ACK for 1'b0
                        //for the read and master ack both slave is pull down
                else
                        output_control <= 1'b1;
        end
        else if (state == STATE_READ)//for read send output shift to SDA
                output_control <= output_shift[7];
        else
                output_control <= 1'b1;
end
endmodule


module i2c_master(
SDA,
SCL,
RST
);
input logic RST;
inout logic SCL;
inout logic SDA;
parameter i2c_delay=5;

reg scl_en;
reg sda_out;
wire sda_in;
assign SDA=sda_out?1'bz:1'b0;
assign sda_in=SDA;

assign SCL=scl_en?1'bz:1'b0;

pullup(SDA);
pullup(SCL);

always@(posedge RST)
begin
	if(RST)
	begin
		sda_out<=1'b1;
		scl_en<=1'b1;
	end
	else
	begin
		sda_out<=sda_out;
		scl_en<=scl_en;
	end
end


//---------------------------------------------------
//-----------------------base function---------------
//---------------------------------------------------
task start_bit();
	sda_out=1'b0;
	#i2c_delay;
	scl_en=1'b0;
	#i2c_delay;
	$display("I2C START\n");
endtask



task stop_bit();
	sda_out=1'b0;
	#i2c_delay;
	scl_en='b1;
	#i2c_delay;
	sda_out=1'b1;
	#i2c_delay;
	$display("I2C STOP\n");
endtask


task send_byte(input logic [7:0] data);
	integer i;
	#i2c_delay;
	for(i=0;i<=7;i=i+1)
	begin
		sda_out=data[7-i];
		#i2c_delay;
		scl_en=1'b1;
		#i2c_delay;
		scl_en=1'b0;
		#i2c_delay;
	end
	$display("SEND BYTE %h\n",data);
endtask

task detect_ack();
	#i2c_delay;
	scl_en=1'b1;
	if(sda_in==1'b0)
		$display("DETECT ACK\n");
	else
		$display($time,"ERROR ACK\n");
	#i2c_delay;
	scl_en=1'b0;
endtask


task restart();
	scl_en=1'b0;
	#i2c_delay;
	sda_out=1'b1;
	#i2c_delay;
	scl_en=1'b1;
	#i2c_delay;
	start_bit();
	$display("I2C RESTART\n");
endtask


task receive_byte(output logic [7:0] data);
	integer i;
	#i2c_delay;
	for(i=0;i<=7;i=i+1)
	begin
		#i2c_delay;
		scl_en=1'b1;
		data[7-i]=sda_in;
		#i2c_delay;
		scl_en=1'b0;
	end
	//gen ack or gen stop;
	$display("RECEIVE BYTE %h\n",data);
endtask

task gen_scl(input int cycles);
	integer i;
	for(i=0;i<cycles;i=i+1)
	begin
		#i2c_delay;
		scl_en=1'b1;
		#i2c_delay;
		scl_en=1'b0;
	end
	#i2c_delay;
	scl_en=1'b1;
	$display("MASTER GEN %d SCL CYCLES\n",cycles);
endtask


task gen_ack();
	#i2c_delay;
	scl_en=1'b0;
	#i2c_delay;
	sda_out=1'b0;
	#i2c_delay;
	scl_en=1'b1;
	#i2c_delay;
	scl_en=1'b0;
	#i2c_delay;
	sda_out=1'b1;
	$display("MASTER GEN ACK\n");
endtask





//-----------------------------------------------------
//-----------------------functions---------------------
//-----------------------------------------------------
task i2c_write(input logic [6:0] addr,input logic [7:0] index,input int N,input logic [7:0] data[$]);
	integer i;
	start_bit();
	send_byte({addr,1'b0});//write
	detect_ack();
	send_byte(index);
	detect_ack();
	for(i=0;i<N;i=i+1)
	begin
		send_byte(data[i]);
		detect_ack();
	end
	stop_bit();
	gen_scl(3);//for detect the stop to idle
	$display("write Bytes=%d to Addr=%h\n",N,addr);
	foreach	(data[j])
        /* verilator lint_off WIDTHEXPAND */
		$display("index=%d,data=%h\n",index+j,data[j]);
endtask



task i2c_read(input logic [6:0] addr,input logic [7:0] index,input int N,output logic [7:0] data[$]);
	integer i;
	start_bit();
	send_byte({addr,1'b0});//write
	detect_ack();
	send_byte(index);
	detect_ack();
	
	restart();
	send_byte({addr,1'b1});//read
	detect_ack();
	for(i=0;i<N;i=i+1)
	begin
		receive_byte(data[i]);
		if(i==N-1)//last data
		begin
			gen_scl(3);//no ack to jump to idle
			stop_bit();
		end
		else
			gen_ack();
	end
	$display("read Bytes=%d to Addr=%h\n",N,addr);
	foreach (data[j])
		$display("index=%d,data=%h\n",index+j,data[j]);
endtask




endmodule