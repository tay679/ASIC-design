//2 port memory, fetches vector value and updates processor buffer. 
module mem_buffer1 (DATAOUT, full, empty, clk, reset, wn, rn, DATAIN); //for storing matrix column indices from memory and to supply to HHT
  output reg [31:0] DATAOUT;
  output reg full, empty;
  input [31:0] DATAIN;
  input clk, reset, wn, rn; 
  
  reg [2:0] wptr;
  reg [2:0] rptr; 
  reg [31:0] memory [0:7]; // the stack is 32 bit wide and 8 locations in size
  reg [31:0] mem,r_mem;
  
  always @(posedge clk)
  begin
    if (!reset)
      begin
        wptr = 3'b000;
        rptr = 3'b000; 
        full = 1'b0;
        empty = 1'b1;
      end
    else if (wn && !full)
      begin
        mem = DATAIN;
        memory[wptr] = mem;
        wptr = wptr + 1;
      end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
  if (reset && rn)   begin   
        DATAOUT = memory[rptr];  
        rptr = rptr + 1;
    end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
      if(wptr == 3'b111 && rptr == 3'b000)
      	full = 1'b1;
      	else
      	 full = 1'b0;
      if(wptr == rptr)
         empty = 1'b1;
     else
         empty = 1'b0;
  end
endmodule
module mem_buffer2 (DATAOUT, full, empty, clk, reset, wn, rn, DATAIN);//for storing vector values from memory and to supply to HHT

  output reg [31:0] DATAOUT;
  output reg full, empty;
  input [31:0] DATAIN;
  input clk, reset, wn, rn; 
  
  reg [2:0] wptr;
  reg [2:0] rptr; 
  reg [31:0] memory [0:7]; // the stack is 32 bit wide and 8 locations in size
  reg [31:0] mem;
  
  always @(posedge clk)
  begin
    if (!reset)
      begin
        wptr = 3'b000;
        rptr = 3'b000; 
        full = 1'b0;
        empty = 1'b1;
      end
    else if (wn && !full)
      begin
        mem = DATAIN;
        memory[wptr] = mem;
        wptr = wptr + 1;
      end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
  if (reset && rn)   begin    
	DATAOUT = memory[rptr];
        rptr = rptr + 1;
    end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
      if(wptr == 3'b111 && rptr == 3'b000)
      	full = 1'b1;
      	else
      	 full = 1'b0;
      if(wptr == rptr)
         empty = 1'b1;
     else
         empty = 1'b0;
  end
endmodule
module control (clk,base_dat_a,base_dat_b,addr1,addr2,dataIn1,dataIn2,Rst,RD,csize,cpu_addr,hht,regaddr1,regaddr2,rdata,adata); //Control unit of HHT

  input clk,Rst;
  reg [31:0] v_values_base, wdata_col_base;
  input [31:0] base_dat_a,base_dat_b;
  input [31:0] dataIn1,dataIn2,csize,cpu_addr;
  output [31:0] addr1,addr2;
  output reg [4:0] regaddr1,regaddr2;
  output reg [31:0] rdata;
  output reg [4:0] adata;

  reg [31:0]values;
  reg reset,cont;
  input RD;
  reg rd_en1,rd_en2,wr_en1,wr_en2,wn1,wn2;
  wire [31:0]mdata_col,vdata;
  wire [31:0]val,out_val,value;
  wire full, empty;
  wire mem_empty, mem_full,v_full,v_empty;
  reg be_init,fe_init;  
  reg wr,core_done,wn,be_done,fe_done;
  wire [31:0] dataOut1, dataOut2;
  wire start;
  wire [31:0] data_req,vdata_req;
  output reg hht;
  logic [4:0] v_base,col_base;

  assign rd_en1 = be_init && wn1;
  assign rd_en2 = fe_init && wn2;
  assign wr_en1 = wn1 && !full;
  assign wr_en2 = wn2 && !full;
  assign fe_init = cont && !fe_done;
  assign start = reset;
  assign be_init = (be_done == 1'b0 && !full)?1'b1:1'b0;
  assign reset = !Rst?(1'b0):(1'b1);
  assign addr1 = (be_init && !full)?data_req:31'd0;
  assign addr2 = (fe_init && !full)?vdata_req:31'd0;
  assign dataOut1 = (wr_en1 && rd_en1)?dataIn1: dataOut1;
  assign dataOut2 = (wr_en2 && rd_en2)?dataIn2: dataOut2;
  
  always @ (posedge clk)begin
     if(!reset) begin
    	v_base = 5'd2; 
    	col_base = 5'd6;
    	hht =  1'b0;
  	end else if (hht) begin
  		regaddr1 = col_base;
  		regaddr2 = v_base;
  		wdata_col_base = base_dat_a;
  		v_values_base = base_dat_b;
  	end else if (cpu_addr >= 32'd3 && cpu_addr <= 32'd126)
  		hht = 1'b1;
  		
  //$display("IN HHT: %d,%d,%d,%d,%b",v_values_base,wdata_col_base ,row_base,matrix_base,hht);
  //$display("%b,%b",be_init,fe_init);
  end

  backend be1 (clk,reset,be_init,wdata_col_base,data_req,wn1,be_done,mdata_col,value,cont,csize);
  mem_buffer1 mbuff1(mdata_col, mem_full, mem_empty, clk, reset, wr_en1, rd_en1, dataOut1);
  mem_buffer2 vbuff1(vdata, v_full, v_empty, clk, reset, wr_en2, rd_en2, dataOut2);
  frontend fe1 (clk,reset,fe_init,v_values_base,value,val,dataOut2,fe_done,wn2,vdata_req,csize); 				
  fifo_buffer f2(adata,rdata,full, empty, clk, reset, start, RD, val);

endmodule

module backend(clk,reset,be_init,wdata_col_base,data_req,wn,be_done,rdata_col,value,cont,csize);
 // parameter V_SIZE = 3;
 // parameter COL_SIZE = 5;
  input clk,be_init,reset;
  input [31:0] wdata_col_base,csize;
  input [31:0] rdata_col;
  output reg [31:0] data_req;
  reg [31:0] m_base;
  reg [31:0] count;
  output reg wn;
  output reg be_done,cont;
  output reg [31:0] value;
  reg [31:0] cols;

always @(posedge clk) begin
     if(!reset) begin
        count = 32'd0;
        m_base = 32'd0;
	wn = 1'b0;
	be_done = 1'b0;
	cont = 1'b0;
	value = 32'd0;
     end 
    else if (be_init && count == csize+32'd3) begin //first few cycles until the first index is obtained from memory  
      	cont = 1'b1;
      	cols = rdata_col; // storing value from memory
      	data_req = m_base; //requesting mat col address
      	value = cols;//sending to backend
	count  = count + 32'd1;
	wn = 1'b1;
    end
    else if (be_init && count <=32'd2)
	begin
	cont = 1'b1;
	wn = 1'b1;
	data_req = m_base;
	cols = rdata_col;
	value = cols;
	count = count +32'd1;
    end
    else if(be_init) begin
	cont = 1'b1;
	m_base = m_base + 32'd1;
	data_req = wdata_col_base + m_base;//requesting mat col address
	count = count +32'd1;
	wn = 1'b1;
	cols = rdata_col;
	value = cols;
    end
    else begin
 	cols = rdata_col;
 	//cont = 1'd0;
    end
  end
endmodule

module frontend(clk,reset,fe_init,v_values_base,value,val,v_val,fe_done,wn,vdata_req,csize);

  input clk,fe_init,reset;
  input [31:0]value,csize;
  input [31:0] v_values_base,v_val;
  output reg [31:0]val,vdata_req;
  output reg wn;
  output reg fe_done;
  reg [31:0] count;
  reg [31:0] mv_val,v_base;


  always @ (posedge clk) begin
 	if (!reset) begin
		val = 31'd0;
		//core_done = 1'b0;
		count = 32'd0;
		fe_done = 1'b0;
		wn = 1'b0;
		v_base = v_values_base;
	end
	else if(fe_init && count <=32'd1) begin
		wn = 1'b1;
		v_base = v_values_base; //vector value address
		count = count + 32'd1;
    	end

	 else if(fe_init) begin
		wn = 1'b1;
		vdata_req = v_base + value;
      		mv_val = v_val; //value obtained after 1 cycle even for the first address
      		val = mv_val;//output the value into processor buffer
		count = count + 32'd1;
    	end
    else if(!fe_init) begin
    	wn = 1'b0;
    end
    	if(count == csize<<1) begin
		fe_done = 1'b1;
		wn = 1'b0;
    	end
  end
endmodule
module fifo_buffer (ADDR,DATAOUT, full, empty, clk, reset, wn, rn, DATAIN); //Processor buffer
  output reg [31:0] DATAOUT;
  output reg [4:0] ADDR;
  output reg full, empty;
  input [31:0] DATAIN;
  input clk, reset, wn, rn; 
  
  reg wptr;
  reg rptr; 
  reg [31:0] memory[0:7]; // the stack is 32 bit wide
  reg [31:0] mem,r_mem;
  
  always @(posedge clk)
  begin
    if (!reset)
      begin
        wptr = 1'b0;
        rptr = 1'b0; 
        full = 1'b0;
        empty = 1'b1;
      end
    else if (wn && !full)
      begin
        mem = DATAIN;
        memory[wptr] = mem;
        wptr = wptr + 1;
      end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
  if (reset && rn)   begin   
        DATAOUT = memory[rptr]; 
    if(rptr)
    	ADDR = 5'd26;
    else
    	ADDR = 5'd25;
    
        rptr = rptr + 1;
    end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
      if(wptr == 1'b1 && rptr == 1'b0)
      	full = 1'b1;
      	else
      	 full = 1'b0;
      if(wptr == rptr)
         empty = 1'b1;
     else
         empty = 1'b0;
   // $display("Processor buffer: %d",DATAOUT);
  end
endmodule













/*//2 port memory, fetches vector value and updates processor buffer. 
module mem_buffer1 (DATAOUT, full, empty, clk, reset, wn, rn, DATAIN); //for storing matrix column indices from memory and to supply to HHT
  output reg [31:0] DATAOUT;
  output reg full, empty;
  input [31:0] DATAIN;
  input clk, reset, wn, rn; 
  
  reg [2:0] wptr;
  reg [2:0] rptr; 
  reg [31:0] memory [0:7]; // the stack is 32 bit wide and 8 locations in size
  reg [31:0] mem,r_mem;
  
  always @(posedge clk)
  begin
    if (!reset)
      begin
        wptr = 3'b000;
        rptr = 3'b000; 
        full = 1'b0;
        empty = 1'b1;
      end
    else if (wn && !full)
      begin
        mem = DATAIN;
        memory[wptr] = mem;
        wptr = wptr + 1;
      end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
  if (reset && rn)   begin   
        DATAOUT = memory[rptr];  
        rptr = rptr + 1;
    end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
      if(wptr == 3'b111 && rptr == 3'b000)
      	full = 1'b1;
      	else
      	 full = 1'b0;
      if(wptr == rptr)
         empty = 1'b1;
     else
         empty = 1'b0;
  end
endmodule
module mem_buffer2 (DATAOUT, full, empty, clk, reset, wn, rn, DATAIN);//for storing vector values from memory and to supply to HHT

  output reg [31:0] DATAOUT;
  output reg full, empty;
  input [31:0] DATAIN;
  input clk, reset, wn, rn; 
  
  reg [2:0] wptr;
  reg [2:0] rptr; 
  reg [31:0] memory [0:7]; // the stack is 32 bit wide and 8 locations in size
  reg [31:0] mem;
  
  always @(posedge clk)
  begin
    if (!reset)
      begin
        wptr = 3'b000;
        rptr = 3'b000; 
        full = 1'b0;
        empty = 1'b1;
      end
    else if (wn && !full)
      begin
        mem = DATAIN;
        memory[wptr] = mem;
        wptr = wptr + 1;
      end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
  if (reset && rn)   begin    
	DATAOUT = memory[rptr];
        rptr = rptr + 1;
    end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
      if(wptr == 3'b111 && rptr == 3'b000)
      	full = 1'b1;
      	else
      	 full = 1'b0;
      if(wptr == rptr)
         empty = 1'b1;
     else
         empty = 1'b0;
  end
endmodule
module control (clk,base_dat_a,base_dat_b,addr1,addr2,dataIn1,dataIn2,Rst,RD,csize,cpu_addr,hht,regaddr1,regaddr2,rdata,adata); //Control unit of HHT

  input clk,Rst;
  reg [31:0] v_values_base, wdata_col_base;
  input [31:0] base_dat_a,base_dat_b;
  input [31:0] dataIn1,dataIn2,csize,cpu_addr;
  output [31:0] addr1,addr2;
  output reg [4:0] regaddr1,regaddr2;
  output reg [31:0] rdata;
  output reg [4:0] adata;

  reg [31:0]values;
  reg reset,cont;
  input RD;
  reg rd_en1,rd_en2,wr_en1,wr_en2,wn1,wn2;
  wire [31:0]mdata_col,vdata;
  wire [31:0]val,out_val,value;
  wire full, empty;
  wire mem_empty, mem_full,v_full,v_empty;
  reg be_init,fe_init;  
  reg wr,core_done,wn,be_done,fe_done;
  wire [31:0] dataOut1, dataOut2;
  wire start;
  wire [31:0] data_req,vdata_req;
  output reg hht;
  logic [4:0] v_base,col_base;

  assign rd_en1 = be_init && wn1;
  assign rd_en2 = fe_init && wn2;
  assign wr_en1 = wn1 && !full;
  assign wr_en2 = wn2 && !full;
  assign fe_init = cont && !fe_done;
  assign start = reset;
  assign be_init = (be_done == 1'b0 && !full)?1'b1:1'b0;
  assign reset = !Rst?(1'b0):(1'b1);
  assign addr1 = (be_init && !full)?data_req:31'd0;
  assign addr2 = (fe_init && !full)?vdata_req:31'd0;
  assign dataOut1 = (wr_en1 && rd_en1)?dataIn1: dataOut1;
  assign dataOut2 = (wr_en2 && rd_en2)?dataIn2: dataOut2;
  
  always @ (posedge clk)begin
     if(!reset) begin
    	v_base = 5'd2; 
    	col_base = 5'd6;
    	hht =  1'b0;
  	end else if (hht) begin
  		regaddr1 = col_base;
  		regaddr2 = v_base;
  		wdata_col_base = base_dat_a;
  		v_values_base = base_dat_b;
  	end else if (cpu_addr >= 32'd3 && cpu_addr <= 32'd126)
  		hht = 1'b1;
  		
  //$display("IN HHT: %d,%d,%d,%d,%b",v_values_base,wdata_col_base ,row_base,matrix_base,hht);
  //$display("%b,%b",be_init,fe_init);
  end

  backend be1 (.clk(clk),.reset(reset),.be_init(be_init),.wdata_col_base(wdata_col_base),.data_req(data_req),.wn(wn1),.be_done(be_done),.rdata_col(mdata_col),.value(value),.cont(cont),.csize(csize));
  mem_buffer1 mbuff1(mdata_col, mem_full, mem_empty, clk, reset, wr_en1, rd_en1, dataOut1);
  mem_buffer2 vbuff1(vdata, v_full, v_empty, clk, reset, wr_en2, rd_en2, dataOut2);
  frontend fe1 (.clk(clk),.reset(reset),.fe_init(fe_init),.v_values_base(v_values_base),.value(value),.val(val),.v_val(dataOut2),.fe_done(fe_done),.wn(wn2),.vdata_req(vdata_req),.csize(csize)); 				
  fifo_buffer f2(.ADDR(adata),.DATAOUT(rdata),.full(full), .empty(empty), .clk(clk), .reset(reset), .wn(start), .rn(RD), .DATAIN(val));

endmodule

module backend(clk,reset,be_init,wdata_col_base,data_req,wn,be_done,rdata_col,value,cont,csize);
 // parameter V_SIZE = 3;
 // parameter COL_SIZE = 5;
  input clk,be_init,reset;
  input [31:0] wdata_col_base,csize;
  input [31:0] rdata_col;
  output reg [31:0] data_req;
  reg [31:0] m_base;
  reg [31:0] count;
  reg [33:0] temp;
  output reg wn;
  output reg be_done,cont;
  output reg [31:0] value;
  reg [31:0] cols;

always @(posedge clk) begin
     if(!reset) begin
        count = 32'd0;
        m_base = 32'd0;
	wn = 1'b0;
	be_done = 1'b0;
	cont = 1'b0;
	value = 32'd0;
     end 
    else if (be_init && count == csize+32'd3) begin //first few cycles until the first index is obtained from memory  
      	cont = 1'b1;
      	cols = rdata_col; // storing value from memory
      	data_req = m_base; //requesting mat col address
      	value = cols;//sending to backend
	count  = count + 32'd1;
	wn = 1'b1;
    end
    else if (be_init && count <=32'd2)
	begin
	cont = 1'b1;
	wn = 1'b1;
	m_base = 32'd0;
      	data_req = wdata_col_base; //requesting mat col address
	cols = rdata_col;
	value = cols;
	count = count +32'd1;
    end
    else if(be_init) begin
	cont = 1'b1;
	m_base = m_base + 1'b1;	
	wn = 1'b1;
	cols = rdata_col;
	value = cols;
	temp = wdata_col_base + m_base;//requesting mat col address
	data_req = temp;
	count = count +1'b1;
	if(count == 32'd262139)begin
		count = 32'd3;
		m_base = 32'd1;
	end
    end
    else begin
 	cols = rdata_col;
 	cont = 1'b0;
    end
  end
endmodule

module frontend(clk,reset,fe_init,v_values_base,value,val,v_val,fe_done,wn,vdata_req,csize);

  input clk,fe_init,reset;
  input [31:0]value,csize;
  input [31:0] v_values_base,v_val;
  output reg [31:0]val,vdata_req;
  output reg wn;
  output reg fe_done;
  reg [31:0] count;
  reg [31:0] mv_val,v_base;


  always @ (posedge clk) begin
 	if (!reset) begin
		val = 31'd0;
		//core_done = 1'b0;
		count = 32'd0;
		fe_done = 1'b0;
		wn = 1'b0;
		v_base = v_values_base;
	end
	else if(fe_init && count <=32'd1) begin
		wn = 1'b1;
		v_base = v_values_base; //vector value address
		count = count + 32'd1;
    	end

	 else if(fe_init) begin
		wn = 1'b1;
		vdata_req = v_base + value;
      		mv_val = v_val; //value obtained after 1 cycle even for the first address
      		val = mv_val;//output the value into processor buffer
		count = count + 32'd1;
    	end
    else if(!fe_init) begin
    	wn = 1'b0;
    end
    	if(count == csize<<1) begin
		fe_done = 1'b1;
		wn = 1'b0;
    	end
  end
endmodule
module fifo_buffer (ADDR,DATAOUT, full, empty, clk, reset, wn, rn, DATAIN); //Processor buffer
  output reg [31:0] DATAOUT;
  output reg [4:0] ADDR;
  output reg full, empty;
  input [31:0] DATAIN;
  input clk, reset, wn, rn; 
  
  reg wptr;
  reg rptr; 
  reg [31:0] memory[0:7]; // the stack is 32 bit wide
  reg [31:0] mem,r_mem;
  
  always @(posedge clk)
  begin
    if (!reset)
      begin
        wptr = 1'b0;
        rptr = 1'b0; 
        full = 1'b0;
        empty = 1'b1;
      end
    else if (wn && !full)
      begin
        mem = DATAIN;
        memory[wptr] = mem;
        wptr = wptr + 1;
      end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
  if (reset && rn)   begin   
        DATAOUT = memory[rptr]; 
    if(rptr)
    	ADDR = 5'd26;
    else
    	ADDR = 5'd25;
    
        rptr = rptr + 1;
    end
    else begin
    wptr = wptr;
    rptr = rptr;
    end
      if(wptr == 1'b1 && rptr == 1'b0)
      	full = 1'b1;
      	else
      	 full = 1'b0;
      if(wptr == rptr)
         empty = 1'b1;
     else
         empty = 1'b0;
   // $display("Processor buffer: %d",DATAOUT);
  end
endmodule
*/