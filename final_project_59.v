module final_project_59(Up_Down, Reset, Stop, Hard, Map1, Map2, Map3, Map4, LED, clk);
	input Up_Down, Reset, clk, Stop, Hard;
	output reg [9:0]LED;
	output reg [7:0]Map1,Map2,Map3,Map4;
	
	reg [7:0]Under_Bird =8'b00100001;
	reg [7:0]Jump_Over = 8'b00010000;
	reg [7:0]Down_Role = 8'b00100011;
	reg [7:0]Up_Role =   8'b00010100;
	reg [7:0]Ground =    8'b01110111;
	reg [7:0]barrier =   8'b01110011;
	reg [7:0]bird =      8'b01110101;
	reg [7:0]next;
	
	reg [25:0] sec;
	reg [25:0] Light_Time;
	reg [25:0] Change_Time;
	reg Cal = 0;
	parameter Reset_state = 2'b00; 
	parameter Control_state = 2'b01;
	parameter Time_state = 2'b10; 
	parameter Idle_state = 2'b11;
	
	reg [1:0] state, next_state, Change;
	reg [2:0] Finished;
	
	integer Seed = 0;
	integer Time = 0;
	
	always @(negedge Change[1], negedge Reset) begin
		if(~Reset) begin
			state <= Reset_state;
			Map1 <= Ground;
			Map2 <= Ground;
			Map3 <= Ground;
			Map4 <= Down_Role;
			Finished <= 3'b000;
			LED[2:0] <= 3'b000;
			LED[9:8] <= 2'b11;
			Cal <= 1;
			Time = 0;
		end
		else begin
			Cal = 0; // stop time counter
			if(LED[0])
				Finished = 3'b011;
			state <= next_state;
			if(state == Control_state) begin
				Time = Time + 1;
				if(Time % (10 *(1 + Hard)) == 0) begin 
					LED[2] <= 1;
					LED[1] <= (LED[2])? 1 : 0;
					LED[0] <= (LED[1])? 1 : 0;
					Time = 0;
				end
				if(Up_Down) begin 	//Down
					if(Map3 == barrier) begin
						LED[8] <= 0;
						Map4 <= Down_Role;
						if(~LED[8]) begin
							Finished <= 3'b100;
							LED[9] <= 0;
						end
					end
					else if(Map3 == bird)
						Map4 = Under_Bird;
					else 
						Map4 = Down_Role;
				end
				else begin			//Up
					if(Map3 == bird) begin
						LED[8] <= 0;
						Map4 = Up_Role;
						if(~LED[8]) begin
							Finished <= 3'b100;
							LED[9] <= 0;
						end
					end
					else if(Map3 == barrier)
						Map4 = Jump_Over;
					else
						Map4 = Up_Role;
				end
				begin //map register shift
					Map3 <= Map2;
					Map2 <= Map1;
					//choose next map
					if(Seed == 0) begin 
						Map1 <= barrier;
					end
					else if(Seed == 1) begin
						Map1 <= Ground;
					end
					else if(Seed == 2) begin
						Map1 <= bird;
					end
				end
			end
			else if(state == Idle_state) begin
				Cal = 1;
				LED[2:0] <= 3'b000;
				LED[9:8] <= 2'b00;
				if(Finished == 3'b100) begin //lose
					Map4 <= 8'b11000111;
					Map3 <= 8'b11000000;
					Map2 <= 8'b10010010;
					Map1 <= 8'b10000110;
				end
				else if(Finished == 3'b011) begin //win
					Map4 <= 8'b10000010;
					Map3 <= 8'b01111111;
					Map2 <= 8'b10000010;
					Map1 <= 8'b01111111;
				end
			end
			Cal = ~Cal;
		end
	end

	always @(state, next_state) begin
		case(state)
			Reset_state:
				next_state = Time_state;
			Control_state:
				if(Finished == 3'b011 || Finished == 3'b100)
					next_state = Idle_state;
				else 
					next_state = Time_state;
			Time_state:
				if(Finished == 3'b011 || Finished == 3'b100)
					next_state = Idle_state;
				else 
					next_state = Control_state;
			Idle_state:
			;
		endcase
	end
	
	always @(posedge clk && !Stop) begin
		sec = sec + 1;
		if(!Cal) begin
			sec = 0;
			Change[0] <= 0;
			Change[1] <= 0;
			LED[6] <= 0;
			LED[5] <= 0;
			LED[4] <= 0;
		end
		else begin 
			if(sec % Change_Time == 0) begin //0.25s per light
				Change[0] <= (Change[0])? 0 : 1;
				Change[1] <= ((!Change[0] && Change[1]) || (Change[0] && !Change[1]))? 1 : 0;
			end
			if(sec % Light_Time == 0) begin
				LED[6] <= (LED[4] && LED[5])? 0 : 1;
				LED[5] <= (LED[6] && !LED[4])? 1 : 0;
				LED[4] <= (LED[5] && !LED[4])? 1 : 0;
			end
		end
	end
	always @(posedge clk && !Stop) begin
		Seed = Seed + 1;
		if(Seed > 2)
			Seed = 0;
	end
	
	always @(Hard) begin
		case (Hard)
			0: begin
				Light_Time = 12_500_000; 
				Change_Time = 6_250_000;
			end
			1: begin
				Light_Time = 6_250_000;
				Change_Time = 3_125_000;
			end
		endcase
	end

endmodule 