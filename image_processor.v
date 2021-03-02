module image_processor(clk, rst, rst1, data_r, data_g, data_b, hsync, vsync, clk_25M, filter, k_in, store, led_store, led_display, div);

input clk,rst;
input rst1;
input [2:0] filter; 		//set filter enable inputs
   	parameter ID=3'd0;   	//identity
   	parameter INV=3'd1;     //invert 
   	parameter BL=3'd2;      //brighten        
   	parameter BR=3'd3;      //blur
   	parameter CUST=3'd4;    //custom  

input [2:0]k_in;           	//custom kernel inputs
input store;			//store values signal (button)
input div;			//choose between custom divide options (switch)


///////////////////////////////////////////////////////////////////////////////VGA

   
parameter    WIDTH  = 200;    		//image width
parameter    HEIGHT  = 200;   		//image height

output reg [7:0] data_r;		//RGB outputs
output reg [7:0] data_g;
output reg [7:0] data_b;
output reg hsync;			//horizontal synchronization signal
output reg vsync;			//vertical synchronization signal
output clk_25M;				//25MHz VGA clk

reg [9:0] x_cnt;			//horizontal counter
reg [9:0] y_cnt;			//vertical counter


frequency_divider_by2 my_fdb2(clk,rst,clk_25M); // generate VGA_clock


   parameter H_SYNC_END   = 96;     	//h-sync end time
   parameter V_SYNC_END   = 2;      	//V- sync end time
   parameter H_SYNC_TOTAL = 800;    	//h-total
   parameter V_SYNC_TOTAL = 524;    	//v-total
	
																									
   always@(posedge clk_25M or negedge rst)	//horizontal scan
   begin  
       if(!rst) begin x_cnt <= 10'd0;end
       else if (x_cnt == H_SYNC_TOTAL) begin x_cnt <= 10'd0;end
       else begin x_cnt <= x_cnt + 1'b1;end
   end
   
   always@(posedge clk_25M or negedge rst)	//vertical scan
   begin    
       if(!rst) begin y_cnt <= 10'd0;end
       else if  (y_cnt == V_SYNC_TOTAL)begin y_cnt <= 10'd0;end
       else if (x_cnt == H_SYNC_TOTAL) begin y_cnt <= y_cnt + 1'b1;end
       else begin y_cnt <= y_cnt;end
   end
    
   always@(posedge clk_25M or negedge rst)  	//H_SYNC signal  
   begin
       if(!rst) begin hsync <= 1'd0;end
       else if (x_cnt == 10'd0)begin hsync <= 1'b0;end
       else if (x_cnt == H_SYNC_END)begin hsync <= 1'b1;end
       else  begin hsync <= hsync;end
   end
    
   always@(posedge clk_25M or negedge rst)	//V_SYNC signal
   begin    
       if(!rst) begin vsync <= 1'd0;end
       else if (y_cnt == 10'd0) begin vsync <= 1'b0;end
       else if (y_cnt == V_SYNC_END) begin vsync <= 1'b1;end
       else  begin vsync <= vsync;   end
   end 
    
 
 ///////////////////////////////////////////////////////////////////////////////Memory
 
 
// addresses for all memories
    reg [15:0] addr;
     reg [15:0] addr1;
      reg [15:0] addr2;
       reg [15:0] addr3;
        reg [15:0] addr4;
         reg [15:0] addr5;
          reg [15:0] addr6;
           reg [15:0] addr7;
            reg [15:0] addr8;
				
// output for all memories
    wire[7:0] q;
    wire[7:0] q1;
    wire[7:0] q2;
    wire[7:0] q3;
    wire[7:0] q4;
    wire[7:0] q5;
    wire[7:0] q6;
    wire[7:0] q7;
    wire[7:0] q8;
    
// memory module for retrieving image data from ROM
    MEM myPic(addr,clk_25M,q);
    MEM1 myPic1(addr1,clk_25M,q1);
    MEM2 myPic2(addr2,clk_25M,q2);
    MEM3 myPic3(addr3,clk_25M,q3);
    MEM4 myPic4(addr4,clk_25M,q4);
    MEM5 myPic5(addr5,clk_25M,q5);
    MEM6 myPic6(addr6,clk_25M,q6);
    MEM7 myPic7(addr7,clk_25M,q7);
    MEM8 myPic8(addr8,clk_25M,q8);
    
    
///////////////////////////////////////////////////////////////////////////////State Machine


parameter ST=4'd0;
parameter identity=4'd1;
parameter blur=4'd2;
parameter brighten=4'd3;
parameter invert=4'd4;                	//set states
parameter custom=4'd5;
	parameter input_value=4'd6;
   	parameter store_value=4'd7;
	parameter check=4'd8;
	parameter i_increment=4'd9;
   	parameter display_custom=4'd10; 

reg [3:0]S;				//state machine control bits
reg [3:0]NS;
reg [2:0]k[0:8];			//kernel register
reg [2:0]k_custom[0:8];                 //custom kernel storage register
reg [6:0]divide;			//divide value register
reg [3:0]i;				//index

output reg [8:0] led_store;		//output LED signals
output reg led_display;

always@(posedge clk_25M or negedge rst)	//set state machine clock to VGA clock to synchronize with VGA output
begin 
	if (rst==1'b0) begin
		S<=NS; end
   	else begin
        	S<=NS; end
end

always@(*)					//State Transition Controls
      	case(S)
		ST: begin					//START state for code initialization
			case(filter)				//case statement instantly directs to selected filter
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
              			CUST: 	NS=custom;
            		endcase
         	end
			
		identity:begin					//IDENTITY state for identity kernel
			case(filter)
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
               			CUST: 	NS=custom;
            		endcase
         	end
			
        	blur:begin					//BLUR state for gaussian blur kernel
           		case(filter)
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
              			CUST: 	NS=custom;
            		endcase
        	end
			
         	brighten:begin					//BRIGHTEN state for brighten kernel
            		case(filter)
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
               			CUST: 	NS=custom;
            		endcase
         	end
			
         	invert:begin					//INVERT state directs to inversion formula (NOT a kernel implementation)
           		case(filter)
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
               			CUST: 	NS=custom;
            		endcase
         	end
			
		custom:begin            			//CUSTOM state initiates custom kernel filter sequence by sending automatically to INPUT_VALUE
			case(filter)
				ID:  	NS=identity;
				INV: 	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
               			CUST:	if(store==1) begin
						NS=input_value; end
				 	else begin
				        	NS=custom; end
            		endcase
		end
			
		input_value: begin				//INPUT_VALUE state waits for user button push to send to STORE_VALUE
            		case(filter)
				ID: 	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
              	 		CUST:	if(store==0) begin
						NS=store_value; end
					else begin
						NS=input_value; end
            		endcase			
		end
			
		store_value: begin				//STORE_VALUE state automatically sends to check state 
            		case(filter)
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
				CUST: 	NS=check;
            		endcase
		end
				
		check:begin					//CHECK state checks custom_kernel index and if full sends to DISPLAY_CUSTOM
			case(filter)				//else sends to I_INCREMENT to increment kernel index value
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
				CUST:	if(store==1) begin
					NS=i_increment; end
						else if(i>7) begin
							NS=display_custom;end
						else begin
							NS=check; end
			endcase
		end
			
		i_increment:begin				//I_INCREMENT state increments kernel index value and automatically sends back to INPUT_VALUE for next kernel input
            		case(filter)
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
             			BR:   	NS=brighten;
               			CUST: 	NS=input_value;  
			endcase
		end
				
         	display_custom:begin				//DISPLAY_CUSTOM state ends custom kernel sequence and waits for next filter selection
            		case(filter)
				ID:  	NS=identity;
				INV:  	NS=invert;
				BL:   	NS=blur;
               			BR:   	NS=brighten;
               			CUST: 	NS=display_custom;
            		endcase         	
		end
      endcase

always@(posedge clk_25M or negedge rst)		//State outputs
begin
   	if(rst==1'b0) begin					//resets kernel values to identity matrix when rst=0
		k[0]=0;
		k[1]=0;
		k[2]=0;
		k[3]=0;
		k[4]=1;
		k[5]=0;
		k[6]=0;
		k[7]=0;
		k[8]=0;
		led_store[8:0]=0;				//turns off LEDs in case previously turned on from custom state
		led_display=0;
		divide=1; end					//divide by 1 ensures proper image output
	else
	begin
		case(S)
			identity:begin				//sets kernel values to identity matrix
				k[0]=0;
				k[1]=0;
				k[2]=0;
				k[3]=0;
				k[4]=1;
				k[5]=0;
				k[6]=0;
				k[7]=0;
				k[8]=0;
				led_store[8:0]=0;
				led_display=0;
				divide=1; end
				
			blur:begin				//sets kernel values to gaussian blur matrix
				k[0]=1;
				k[1]=2;
				k[2]=1;
				k[3]=2;
				k[4]=4;
				k[5]=2;
				k[6]=1;
				k[7]=2;
				k[8]=1; 
				led_store[8:0]=0;
				led_display=0;
				divide=16; end			//divide set to 16 to ensure sum of kernel values = 0
				
			brighten:begin				//sets kernel values to brighten matrix
				k[0]=0;
				k[1]=0;
				k[2]=0;
				k[3]=0;
				k[4]=3;
				k[5]=0;
				k[6]=0;
				k[7]=0;
				k[8]=0;
				led_store[8:0]=0;
				led_display=0;
				divide=2; end			//divide set to 2 to set appropriate brightness value (makes central kernel value 3/2)
				
			custom:begin				//sets kernel values to identity matrix while kernel inputs are being processed
				k[0]=0;
				k[1]=0;
				k[2]=0;
				k[3]=0;
				k[4]=1;
				k[5]=0;
				k[6]=0;
				k[7]=0;
				k[8]=0;
				divide=1;
				i=0;				//resets kernel register index to 0
				k_custom[0]=0;			//sets custom kernel storage register values to 0
				k_custom[1]=0;
				k_custom[2]=0;
				k_custom[3]=0;
				k_custom[4]=0;
				k_custom[5]=0;
				k_custom[6]=0;
				k_custom[7]=0;		
				k_custom[8]=0;						
				led_store[8:0]=0;		//ensures LED lights are turned off
				led_display=0;end
				
			input_value:begin					
				k[0]=0;
				k[1]=0;
				k[2]=0;
				k[3]=0;
				k[4]=1;
				k[5]=0;
				k[6]=0;
				k[7]=0;
				k[8]=0;
				divide=1;end
				
			store_value:begin						
				k[0]=0;
				k[1]=0;
				k[2]=0;
				k[3]=0;
				k[4]=1;
				k[5]=0;
				k[6]=0;
				k[7]=0;
				k[8]=0;
				divide=1;
				k_custom[i]=k_in;		//stores input values in custom kernel storage register 
				led_store[i]=1;end		//turns on LED particular to present index to inform user value has been stored
				
			check:begin
				k[0]=0;
				k[1]=0;
				k[2]=0;
				k[3]=0;
				k[4]=1;
				k[5]=0;
				k[6]=0;
				k[7]=0;
				k[8]=0;
				divide=1;end
				
			i_increment:begin
				k[0]=0;
				k[1]=0;
				k[2]=0;
				k[3]=0;
				k[4]=1;
				k[5]=0;
				k[6]=0;
				k[7]=0;
				k[8]=0;
				divide=1;
				i=i+1;end			//increments index
				
			display_custom:begin			//assigns custom kernel storage register values to output kernel
				k[0]=k_custom[0];
				k[1]=k_custom[1];
				k[2]=k_custom[2];
				k[3]=k_custom[3];
				k[4]=k_custom[4];
				k[5]=k_custom[5];
				k[6]=k_custom[6];
				k[7]=k_custom[7];
				k[8]=k_custom[8];
				if(div==1)begin			//conditional allows user to choose divide by sum of kernel values (blur) or divide by 1
					divide=k[0]+k[1]+k[2]+k[3]+k[4]+k[5]+k[6]+k[7]+k[8];end	
				else begin
					divide=1;end
				led_display=1;end		//turns output LED on to inform user that custom kernel has been applied to photo
		endcase
	end
end


///////////////////////////////////////////////////////////////////////////////Assign RGB outputs


always@(posedge clk_25M or negedge rst1)
begin
	if (!rst1) begin																	//sets RGB values to 0 when rst = 0
 
             data_r=8'b00000000;
             data_g=8'b00000000;
             data_b=8'b00000000;
             addr = 0;
            
   end
                
	else if(350<=x_cnt&&x_cnt<550 && 150<=y_cnt&&y_cnt<350 ) begin  //conditional for assigning RGB values when x count and y count are in the display range
	
		if(S==invert) begin 					//executes inversion algorithm when state=INVERT
			
			data_b[7:6]= 3-q[1:0];
			data_b[5:0]= 6'b111111;
	
			data_g[7:5]= 7-q[4:2];
			data_g[4:0]= 5'b11111;
			
			data_r[7:5]= 7-q[7:5];
			data_r[4:0]= 5'b11111;
			addr=(x_cnt-12)+(y_cnt+177)*10'd200;
			
		end 

		else begin 						//executes kernel convolution algorithm during all other states
		
			if(((k[0]*q[1:0]+k[1]*q1[1:0]+k[2]*q2[1:0]+k[3]*q3[1:0]+k[4]*q4[1:0]+k[5]*q5[1:0]+k[6]*q6[1:0]+k[7]*q7[1:0]+k[8]*q8[1:0])/divide)>3)	begin 
				data_b[7:6] = 2'd3;
				data_b[5:0]= 6'b111111;
				end 
		
			else begin 
				data_b[7:6]= ((k[0]*q[1:0]+k[1]*q1[1:0]+k[2]*q2[1:0]+k[3]*q3[1:0]+k[4]*q4[1:0]+k[5]*q5[1:0]+k[6]*q6[1:0]+k[7]*q7[1:0]+k[8]*q8[1:0])/divide);
				data_b[5:0]= 6'b111111;
				end 
	
			if((k[0]*q[4:2]+k[1]*q1[4:2]+k[2]*q2[4:2]+k[3]*q3[4:2]+k[4]*q4[4:2]+k[5]*q5[4:2]+k[6]*q6[4:2]+k[7]*q7[4:2]+k[8]*q8[4:2])/divide>7)	begin
				data_g[7:5]= 3'd7;
				data_g[4:0]= 5'b11111;
				end
			
			else begin
				data_g[7:5]= (k[0]*q[4:2]+k[1]*q1[4:2]+k[2]*q2[4:2]+k[3]*q3[4:2]+k[4]*q4[4:2]+k[5]*q5[4:2]+k[6]*q6[4:2]+k[7]*q7[4:2]+k[8]*q8[4:2])/divide;
				data_g[4:0]= 5'b11111;
				end
	
			if((k[0]*q[7:5]+k[1]*q1[7:5]+k[2]*q2[7:5]+k[3]*q3[7:5]+k[4]*q4[7:5]+k[5]*q5[7:5]+k[6]*q6[7:5]+k[7]*q7[7:5]+k[8]*q8[7:5])/divide>7)	begin
				data_r[7:5]= 3'd7;
				data_r[4:0]= 5'b11111;
				end
				
			else begin
				data_r[7:5]= (k[0]*q[7:5]+k[1]*q1[7:5]+k[2]*q2[7:5]+k[3]*q3[7:5]+k[4]*q4[7:5]+k[5]*q5[7:5]+k[6]*q6[7:5]+k[7]*q7[7:5]+k[8]*q8[7:5])/divide;
				data_r[4:0]= 5'b11111;
				end
  
			addr=(x_cnt-12)+(y_cnt+177)*10'd200-WIDTH-1;		//retrieves values at each kernel address from memory
			addr1=(x_cnt-12)+(y_cnt+177)*10'd200-WIDTH;
			addr2=(x_cnt-12)+(y_cnt+177)*10'd200-WIDTH+1;
			addr3=(x_cnt-12)+(y_cnt+177)*10'd200-1;
			addr4=(x_cnt-12)+(y_cnt+177)*10'd200;
			addr5=(x_cnt-12)+(y_cnt+177)*10'd200+1;
			addr6=(x_cnt-12)+(y_cnt+177)*10'd200+WIDTH-1;
			addr7=(x_cnt-12)+(y_cnt+177)*10'd200+WIDTH;
			addr8=(x_cnt-12)+(y_cnt+177)*10'd200+WIDTH+1;
	
		end 

	end

	else begin																			//otherwise sets RGB to 0
  
             data_r=8'b00000000;

             data_g=8'b00000000;

             data_b=8'b00000000;
               
   end 
	
end 
endmodule


///////////////////////////////////////////////////////////////////////////////VGA clock module


module frequency_divider_by2( clk ,rst,out_clk );
output reg out_clk;
input clk ;
input rst;
always @(posedge clk)
begin
if (~rst)
     out_clk <= 1'b0;
else
     out_clk <= ~out_clk;	
end
	
endmodule
