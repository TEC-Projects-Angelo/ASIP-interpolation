module decode_cycle(
    input clk, rst, RegWriteW, ForwardAD, ForwardBD, ForwardCD, BranchLinkW,
    input [4:0] RDW,
    input [32:0] InstrD, // Instrucción de 34 bits
    input [8:0] PCD, PCPlus4D, PCW, // PC ajustado a 18 bits
    input [17:0] ResultW,
    
    output RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE , PCReturnSignalE,
    output [2:0] ALUControlE,
  output [17:0] RD1_E, RD2_E, RD4_E, Imm_Ext_E,
  output [4:0] RS1_E, RS2_E, RS4_E, RD_E,
    output [8:0] PCE, PCPlus4E, R29_E,
	 output [1:0] RGB_E,
	 output JumpE,
	 output PCDirectionE, BranchLinkE,
	 output [8:0] PCReturnE
);

    // Declaring Interim Wires
    wire RegWriteD, ALUSrcD, MemWriteD, ResultSrcD, BranchD, PCReturnSignalD;
    wire [1:0] ImmSrcD, RGB_D;
    wire [2:0] ALUControlD;
    wire [17:0] RD1_D, RD1_RF, RD2_D, RD2_RF, RD4_D, RD4_RF, Imm_Ext_D;
	 wire JumpD; 
	 wire PCDirectionD, BranchLinkD;
	 wire [8:0] R29_D;

    // Declaration of Interim Register
    reg RegWriteD_r, ALUSrcD_r, MemWriteD_r, ResultSrcD_r, BranchD_r, PCReturnSignalD_r;
    reg [2:0] ALUControlD_r, RGB_D_r;
  reg [17:0] RD1_D_r, RD2_D_r, RD4_D_r, Imm_Ext_D_r;
  reg [4:0] RD_D_r, RS1_D_r, RS2_D_r, RS4_D_r;
    reg [8:0] PCD_r, PCPlus4D_r, R29_D_r;
	 reg [4:0] A2;
	 reg [4:0] A1;
	 reg [4:0] RDW_D;
	 reg [17:0] ResultD;
	 reg JumpD_r;
	 reg  PCDirectionD_r, BranchLinkD_r;
	 
	 
    assign A2 = (InstrD[32] == 1'b0 && InstrD[31:30] == 2'b01 && InstrD[29:28] == 2'b00 && InstrD[31:30] != 2'b01) ? InstrD[4:0]  : InstrD[22:18];
	 assign A1 = (InstrD[31:30] == 2'b11 && InstrD[29:28] == 2'b00)? 5'b11101 :  InstrD[27:23];
	 assign ResultD = (BranchLinkW) ? {9'b0, PCW} : ResultW;
	 
	 Control_Unit_Top control(
    .tipo(InstrD[31:30]),   // Tipo de instrucción
    .op(InstrD[29:28]),     // Operación específica
    .Inm(InstrD[32]),          // Bit de inmediato

	 
    .RegWrite(RegWriteD),    // Habilitar escritura en registros
    .ImmSrc(ImmSrcD),  // Fuente del inmediato
    .ALUSrc(ALUSrcD),      // Selección entre registro o inmediato en la ALU
    .MemWrite(MemWriteD),    // Habilitar escritura en memoria
    .ResultSrc(ResultSrcD),   // Selección del resultado (ALU/memoria)
    .Branch(BranchD),      // Indicar si es una instrucción de salto condicional
    .ALUControl(ALUControlD),  // Control para la ALU
	 .RGB(RGB_D),						// Control de color					// Control de color
	 .Jump(JumpD),
	 .PCDirection(PCDirectionD),
	 .PCReturnSignal(PCReturnSignalD),
	 .BranchLink(BranchLinkD)
);
	 
    // Archivo de registros
    Register_File rf (
        .clk(clk),
        .rst(rst),
        .WE3(RegWriteW),
        .WD3(ResultD),    // Escribimos en registros de 18 bits
        .A1(A1), // Fuente A1 ajustada a la ISA
        .A2(A2),  // Fuente A2 ajustada a la ISA
        .A3(RDW),
		  .A4(InstrD[4:0]),
		  
        .RD1(RD1_RF),      // Lectura de registros de 22 bits
        .RD2(RD2_RF),
        .R29(R29_D),
		  .RD4(RD4_RF)
    );
	 
	 Mux2Parametrizado #(18) RD1_mux (
        .a(RD1_RF),
        .b(ResultW),
        .s(ForwardAD),
        .c(RD1_D)
    );
	 
	 Mux2Parametrizado #(18) RD2_mux (
        .a(RD2_RF),
        .b(ResultW),
        .s(ForwardBD),
        .c(RD2_D)
    );
	 
	 Mux2Parametrizado #(18) RD4_mux (
        .a(RD4_RF),
        .b(ResultW),
        .s(ForwardCD),
        .c(RD4_D)
    );

	 
    // Declaración de lógica de registros
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            RegWriteD_r <= 1'b0;
            ALUSrcD_r <= 1'b0;
            MemWriteD_r <= 1'b0;
            ResultSrcD_r <= 1'b0;
            BranchD_r <= 1'b0;
            ALUControlD_r <= 3'b000;
            RD1_D_r <= 18'd0; 
            RD2_D_r <= 18'd0;
			   RD4_D_r <= 18'd0;	
            Imm_Ext_D_r <= 18'd0;
            RD_D_r <= 5'h00;
            PCD_r <= 9'd0; 
            PCPlus4D_r <= 9'd0;
            RS1_D_r <= 5'h00;
            RS2_D_r <= 5'h00;
				RGB_D_r <= 2'd0;
				JumpD_r <= 1'd0;
				PCDirectionD_r <= 1'd0;
				PCReturnSignalD_r <= 1'd0;
				R29_D_r <= 9'd0;
				BranchLinkD_r <= 1'd0;
        end


        else begin
            RegWriteD_r <= RegWriteD;
            ALUSrcD_r <= ALUSrcD;
            MemWriteD_r <= MemWriteD;
            ResultSrcD_r <= ResultSrcD;
            BranchD_r <= BranchD;
            ALUControlD_r <= ALUControlD;
            RD1_D_r <= RD1_D;
            RD2_D_r <= RD2_D;
			   RD4_D_r <= RD4_D;	
            Imm_Ext_D_r <= InstrD[17:0];
				RD_D_r <= (InstrD[31:30] == 2'b01 && InstrD[29:28] == 2'b00) ? InstrD[22:18]  : 
           (InstrD[32] == 1'b1 && InstrD[31:30] != 2'b11)? InstrD[22:18] : (InstrD[31:28] == 4'b1001) ? 5'd29 : InstrD[4:0];
            PCD_r <= PCD; 
            PCPlus4D_r <= PCPlus4D;
            RS1_D_r <= InstrD[27:23]; // Ajustado para 5 bits
            RS2_D_r <= A2;  // Ajustado para 5 bits
				RS4_D_r <= InstrD[4:0];
				RGB_D_r <= RGB_D;
         JumpD_r <= JumpD;
				PCDirectionD_r <= PCDirectionD;
				PCReturnSignalD_r <= PCReturnSignalD;
				R29_D_r <= R29_D;
				BranchLinkD_r <= BranchLinkD;

        end
    end

    
    // Asignación de las salidas, manejando el 
	 
	assign RegWriteE = RegWriteD_r;
	assign ALUSrcE = ALUSrcD_r;
	assign MemWriteE = MemWriteD_r;
	assign ResultSrcE = ResultSrcD_r;
	assign BranchE = BranchD_r;
	assign ALUControlE = ALUControlD_r;
	assign RD1_E = RD1_D_r;
	assign RD2_E = RD2_D_r;
	assign RD4_E = RD4_D_r;
	assign Imm_Ext_E = Imm_Ext_D_r;
	assign RD_E = RD_D_r;
	assign PCE = PCD_r;
	assign PCPlus4E = PCPlus4D_r;
	assign RS1_E = RS1_D_r;
	assign RS2_E = RS2_D_r;
	assign RS4_E = RS4_D_r;
	assign RGB_E = RGB_D_r;
  	assign JumpE = JumpD_r;
	assign PCDirectionE =  PCDirectionD_r;
	assign PCReturnSignalE = PCReturnSignalD_r;
	assign R29_E = R29_D_r;
	assign BranchLinkE = BranchLinkD_r;

endmodule
