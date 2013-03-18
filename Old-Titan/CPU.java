/* _^_ | but i maintain the copyright rights */


import java.io.FileReader;
import java.io.IOException;
import java.io.BufferedReader;

public class CPU {

   private static final int REG_BITS = 3;
   private static final int ALU_BITS = 7;

   private int pc;            // program counter
   private int A, B, C;       // registers
   private int ALUresult;	// ALU register

   private short instructions[];

   public CPU() {
	instructions = new short[15];
   }

   public void setRegister(int reg, int value) {
	if(reg == 1) A = value & REG_BITS;
	if(reg == 2) B = value & REG_BITS;
	if(reg == 3) C = value & REG_BITS;
	throw new IllegalArgumentException(new StringBuilder().append(reg).toString());
   }

   public int getRegister(int reg) {
	if(reg == 1) return A;
	if(reg == 2) return B;
	if(reg == 3) return C;
	throw new IllegalArgumentException(new StringBuilder().append(reg).toString());
   }

   public void setALU(int alu) {
	ALUresult = alu & ALU_BITS;
   }

   public int getALU() {
	return ALUresult;
   }

   public int getPC() {
	return pc;
   }

   public boolean execute() {

	if(pc == 15) return false;

      pc++;

      int ins = instructions[pc - 1];
      int function = (ins >> 6) & 0xf;                           // get function: bits 10-6
      int specifier = (ins >> 2) & 0xf;                          // get specifier: bits 6-2
      int data = (ins & 0x3);                                    // get data: bits 2-0

      if(function == 0) return false;                            // halt instruction
      else if(function == 1) otherFunction(specifier, data);
      else if(function == 2) addressFunction(specifier, data);
      else if(function == 4) ALUFunction(specifier, data);
      else if(function == 8) pc = (specifier - 1);                     // jump instruction FUCK YOU COCKSUCKER IMPLEMENT IT 
      else crash("Unrecognized function: " + function);
	//System.out.println("function=" + function+" specifier="+specifier+" data="+data);
	//printState();
	//System.out.println();
	return true;

   }

   private void ALUFunction(int specifier, int data) {

      if(specifier == 1) ALUresult = (A + B) & ALU_BITS;
      else if(specifier == 2) ALUresult = (A - B) & ALU_BITS;
      else if(specifier == 3) ALUresult = A | B;
      else if(specifier == 4) ALUresult = A ^ B;
      else if(specifier == 5) ALUresult = A & B;
      else if(specifier == 6) ALUresult = (~A) & ALU_BITS;
      else crash("Unrecognized ALU speficier: " + specifier);

   }

   private void addressFunction(int specifier, int data) {

      int srcReg = specifier >> 2;
      int destReg = specifier & 3;

      int value = 0;				// value of the data to be written

      if(srcReg == 1) value = A;
      else if(srcReg == 2) value = B;
      else if(srcReg == 3) value = C;
      else crash("src register is 00 in WRITE");

      if(destReg == 0) {                  // if dest is 00 (invalid register), this
                                          // copies data from the data bus to src
         value = data;
         destReg = srcReg;

      }

      if(destReg == 1) A = value;
      else if(destReg == 2) B = value;
      else if(destReg == 3) C = value;
      else crash("invalid dest register in WRITE");

   }

   private void otherFunction(int specifier, int data) {
      if(specifier == 1) {
	   if(A != B) pc++;
	}
      // else if(specifier == 2) // FEED ALU OUTPUT TO DATA BUS ????????????/
      else if(specifier == 3) A = ALUresult & REG_BITS;
      else if(specifier == 4) B = ALUresult & REG_BITS;
      else if(specifier == 5) C = ALUresult & REG_BITS;
      else crash("Unknown other function: " + specifier);
   }

   public void loadProgram(BufferedReader br) throws IOException {

      int pos = 0;                  // index of the instruction about to be parsed into the instruction array
      int bitPos = 0;               // index the current bit within the current instruction
      int partial = 0;              // value of all the aggregated instruction bits so far

      String line = br.readLine();

      while(line != null) {

         char chars[] = line.toCharArray();

         for(char c : chars) {
            if(Character.isWhitespace(c)) continue;

            boolean validBit = false;

            if(c == '0') {
               partial <<= 1;
               validBit = true;
            } else if(c == '1') {
               partial <<= 1;
               partial |= 1;
               validBit = true;
            }

            if(validBit) {
               bitPos++;
               if(bitPos == 10) {
                  instructions[pos++] = (short)partial;
                  bitPos = partial = 0;
                  if(pos == 15) {
                     System.out.println("Warning: Program too large. Program has been truncated.\n" +
                                        "Maximum of 150 bits (15 instructions) supported");
                     return;
                  } // truncation warning
               } // complete instruction
            } else break; // valid bit value ('0' or '1')
         } // parse chars

         line = br.readLine();

      }

   }

   private void crash(String uhoh) {

      System.out.println("*** COMPLETE PROCESSOR ERROR SHUT DOWN ***");
	printState();
      throw new RuntimeException(uhoh);

   }

   private void printState() {

	System.out.println("pc=" + pc);
      System.out.println("A=" + A + " B=" + B + " C=" + C);
      System.out.println("ALU=" + ALUresult);

   }

}