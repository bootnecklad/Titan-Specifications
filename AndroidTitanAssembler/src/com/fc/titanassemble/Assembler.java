package com.fc.titanassemble;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

/**
 * Created by IntelliJ IDEA. User: Uncalled For Date: 23/03/12 Time: 21:41
 */
public class Assembler {

	public static final String[] mnemonics = { "NOP", "ADD", "ADC", "SUB",
			"AND", "LOR", "XOR", "NOT", "SHR", "INT", "RTE", "PSH", "POP",
			"MOV", "CLR", "XCH", "JMP", "JPZ", "JPS", "JPC", "JPI", "JSR",
			"RTN", "JMI", "LDI", "STI", "LDC", "LDM", "STM", "SHL", "TST" };
	public static final int[] opcodeValue = { 0x00, 0x10, 0x11, 0x12, 0x13,
			0x14, 0x15, 0x16, 0x17, 0x20, 0x21, 0x70, 0x80, 0x90, 0x60, 0x91,
			0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA8, 0xC8, 0xC0, 0xD0,
			0xE0, 0xF0, 0x10, 0x15 };
	public static final int[] insLengths = { 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1,
			1, 1, 2, 1, 2, 3, 3, 3, 3, 3, 3, 1, -1, -1, -1, 2, 3, 3, 2, 2 };
	public static final String[] registerNames = { "R0", "R1", "R2", "R3",
			"R4", "R5", "R6", "R7", "R8", "R9", "RA", "RB", "RC", "RD", "RE",
			"RF" };
	public static final int[] registerValues = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
			10, 11, 12, 13, 14, 15 };

	private File inputFile, outputFile;
	private ArrayList<String> lines = new ArrayList<String>();
	private ArrayList<Byte> bytes = new ArrayList<Byte>();
	private HashMap<String, Integer> labels = new HashMap<String, Integer>();
	private int addressOffset = 0;

	public Assembler(String in, String out) {
		inputFile = new File(in);
		outputFile = new File(out);

		for (int i = 0; i < registerNames.length; i++) { // Add set registers to
															// labels
			labels.put(registerNames[i], registerValues[i]);
		}
	}

	public Assembler(String in) {
		this(in, "output.o");
	}

	public boolean readLines(final int addressOffset) throws IOException {
		lines.clear(); // remove all previous lines/ labels

		String currentLine;
		BufferedReader br = new BufferedReader(new FileReader(inputFile));

		this.addressOffset = addressOffset; // for future use
		int addressCounter = addressOffset;

		while ((currentLine = br.readLine()) != null) {
			currentLine = currentLine.trim();

			if (!(currentLine.startsWith(";") || currentLine.length() == 0)) {
				String[] split = currentLine.split(" ");
				int insIndex = getMnemonicIndex(split[0]);

				if (insIndex != -1) { // If line is an instruction.
					if (insIndex == 9) { // If line begins with INT
						if (split[1].charAt(split[1].length() - 1) == ':') { // Check
																				// if
																				// INT
																				// label
							labels.put(split[1].split(":")[0], addressCounter);
						}
					}

					if (insLengths[insIndex] == -1) { // Handle variable length
														// instructions
						addressCounter += split[1].contains("[") ? 2 : 3; // Dirty
																			// hack
																			// :)
					} else {
						addressCounter += insLengths[insIndex];
					}
					currentLine = currentLine.split(";")[0]; // Removes comments

				} else if (split[0].startsWith(".")) { // If line is data
					if (split[0].equalsIgnoreCase(".WORD")) {
						labels.put(split[1],
								Integer.valueOf(split[2].substring(2), 16)); // puts
																				// value
					} else {
						labels.put(split[1], addressCounter); // puts address
																// (.byte,.data,.ascii)
						addressCounter += countDataBytes(currentLine, split);
					}

				} else { // Assume line is a label
					currentLine = currentLine.split(";")[0]; // Removes comments
					currentLine = currentLine.trim();
					split = currentLine.split(" ");
					if (split[0].charAt(split[0].length() - 1) == ':'
							&& split.length == 1) { // Take as label only if one
													// word, and ends with ":"
						labels.put(split[0].split(":")[0], addressCounter);
					}
				}

				lines.add(currentLine);
			}

		}
		return true;
	}

	public boolean assembleLines() {
		bytes.clear();

		for (String currentLine : lines) {
			String[] split = currentLine.split(" ");
			int insIndex = getMnemonicIndex(split[0]);

			if (insIndex != -1 && !(currentLine.contains(":"))) { // If line is
																	// an
																	// instruction.
				byte[] data = null;
				try {
					data = getInstructionBytes(currentLine, split, insIndex);
				} catch (Exception e) {
					System.err.println("Error assembling line: ");
					System.err.println(currentLine);
					e.printStackTrace();
					//System.exit(0);
				}
				for (byte b : data) { // Add instruction bytes to assembled
										// bytes
					bytes.add(b);
				}

			} else if (split[0].startsWith(".")
					&& !split[0].startsWith(".WORD")
					&& !split[0].startsWith(".ORIG")) { // If line is data but
														// not .WORD
				byte[] data = getDataBytes(currentLine, split);
				for (byte b : data) { // Add data bytes to assembled bytes
					bytes.add(b);
				}

			} else if (split[0].equals(".ORIG")) { // If origin
				byte[] values = getValues(split[1]);
				int address = (values[0] << 8) + values[1];
				System.out.println("Program starts at "
						+ split[1]
						+ " Address: "
						+ addressString(Integer.toHexString(address))
								.toUpperCase());

			} else { // Assume line is a label
				// All labels are pre-processed
			}
		}
		return true;
	}

	public int getMnemonicIndex(String ins) {
		for (int i = 0; i < mnemonics.length; i++) {
			if (ins.equalsIgnoreCase(mnemonics[i])) {
				return i; // returns index of instruction
			}
		}
		return -1; // returns -1 if not found
	}

	private byte[] getInstructionBytes(String line, String[] split, int insIndex)
			throws Exception {
		line = line.toUpperCase();
		split = line.split(" "); // Ensure everything is in upper case
		byte[] result;
		if (insIndex == 23 || insIndex == 24 || insIndex == 25) { // If
																	// instruction
																	// length is
																	// variable
			result = new byte[split[1].contains("[") ? 2 : 3]; // dirty hack #2

		} else {
			result = new byte[insLengths[insIndex]]; // set array length to
														// number of bytes in
														// instruction
		}

		result[0] = (byte) opcodeValue[insIndex]; // Set base opcode value

		switch (insIndex) {
		case 1: // ADD
		case 2: // ADC
		case 3: // SUB
		case 4: // AND
		case 5: // LOR
		case 6: // XOR
			result[1] = getTwoRegisters(split[1]);
			break;

		case 7: // NOT
		case 8: // SHR
			result[1] = (byte) (labels.get(split[1]) << 4);
			break;

		case 9: // INT
			result[1] = getValue(split[1]);
			break;

		case 11: // PSH
		case 12: // POP
			result[0] += labels.get(split[1]);
			break;

		case 13: // MOV
		case 15: // XCH
			result[1] = getTwoRegisters(split[1]);
			break;

		case 14: // CLR
			result[0] += getValue(split[1]);
			break;

		case 16: // JMP
		case 17: // JPZ
		case 18: // JPS
		case 19: // JPC
		case 20: // JPI
		case 21: // JSR
			byte[] bytes = getValues(split[1]);
			result[1] = bytes[0];
			result[2] = bytes[1];
			break;

		case 23: // JMI
			if (split[1].contains("[")) {
				result[0] += 0x01; // Add 1 to opcode
				String vars = split[1].substring(1).split("]")[0];
				result[1] = getTwoRegisters(vars);

			} else {
				byte[] address = getValues(split[1]);
				result[1] = address[0];
				result[2] = address[1];
			}
			break;

		case 24: // LDI
		case 25: // STI
		case 27: // LDM
		case 28: // STM
			String[] split1 = split[1].split(",");
			result[0] += getValue(split1[0]);

			if (split1[1].charAt(0) == '[') {
				result[0] -= 0x10; // Subtract from opcode
				String regs = split[1].substring(split[1].indexOf(',') + 2,
						split[1].length() - 1);
				result[1] = getTwoRegisters(regs);

			} else {

				byte[] address = getValues(split1[1]);
				result[1] = address[0];
				result[2] = address[1];
			}
			break;

		case 26: // LDC
			String[] split2 = split[1].split(",");
			result[0] += getValue(split2[0]);
			result[1] = getValue(split2[1]);
			break;

		case 29: // SHL
		case 30: // TST
			byte reg = getValue(split[1]);
			result[1] = (byte) (reg + (reg << 4)); // Puts same register twice
			break;

		}
		return result;
	}

	private byte getValue(String val) {
		if (val.toUpperCase().startsWith("0X")) { // If value
			int value = Integer.valueOf(val.substring(2), 16);
			return (byte) value;

		} else { // If label
			int value = labels.get(val);
			return (byte) value;
		}
	}

	private byte[] getValues(String val) {
		if (val.toUpperCase().startsWith("0X")) { // If value
			int value = Integer.valueOf(val.substring(2), 16);
			return new byte[] { ((byte) ((value >> 8) & 0xff)),
					((byte) (value & 0xff)) };

		} else { // If label
			int value = labels.get(val); // split address into two bytes.
			return new byte[] { ((byte) ((value >> 8) & 0xff)),
					((byte) (value & 0xff)) };
		}
	}

	private byte getTwoRegisters(String line) {
		String[] registers = line.split(",");

		int source = labels.get(registers[0]);
		int destination = labels.get(registers[1]);
		return (byte) ((source << 4) + destination);
	}

	private int countDataBytes(String line, String[] split) {
		if (split[0].equalsIgnoreCase(".BYTE")) {
			return 1;

		} else if (split[0].equalsIgnoreCase(".DATA")) {
			return split.length - 2;

		} else if (split[0].toUpperCase().startsWith(".ASCI")) {
			int length = line.split("\"")[1].split("\"")[0].length(); // Gets
																		// length
																		// of
																		// string.
			if (split[0].equalsIgnoreCase(".ASCIZ")) {
				length++; // Increments length to accommodate null terminator.
			}
			return length;
		} else {
			return 0;
		}
	}

	private byte[] getDataBytes(String line, String[] split) {
		if (split[0].equalsIgnoreCase(".BYTE")) {
			int[] result = { Integer.valueOf(split[2].substring(2)
					.toUpperCase(), 16) }; // Get byte or word
			return intToByteArray(result);

		} else if (split[0].equalsIgnoreCase(".DATA")) {
			line = line.split(";")[0]; // Ensure comments are removed
			split = line.split(" ");
			int[] bytes = new int[split.length - 2];
			for (int i = 0; i < bytes.length; i++) {
				bytes[i] = Integer.valueOf(split[2 + i].substring(2)
						.toUpperCase(), 16);
			}
			return intToByteArray(bytes); // return data array

		} else if (split[0].toUpperCase().startsWith(".ASCI")) {
			String theString = line.split("\"")[1].split("\"")[0]; // Gets
																	// string

			if (split[0].equalsIgnoreCase(".ASCIZ")) {

				byte[] bytes = Arrays.copyOf(theString.getBytes(),
						theString.length() + 1);
				bytes[bytes.length - 1] = 0x00; // Sets last byte to null

				int[] result = new int[bytes.length];
				for (int i = 0; i < result.length; i++) { // Convert byte array
															// to int array :(
					result[i] = (int) bytes[i];
				}
				return intToByteArray(result); // Returns null terminated string
			}

			return theString.getBytes();// Returns string

		} else {
			return null;
		}
	}

	public byte[] intToByteArray(int[] array) {
		byte[] result = new byte[array.length];
		for (int i = 0; i < result.length; i++) {
			result[i] = (byte) (array[i] & 0xFF);
		}
		return result;
	}

	public String getBytes(int bytesPerLine) {
		StringBuilder sb = new StringBuilder();
		for (int i = 0, j = addressOffset; i < bytes.size(); i++, j++) {
			if ((i % bytesPerLine) == 0) {
				sb.append("\n");
				sb.append(addressString(Integer.toHexString(j)).toUpperCase()
						+ "      ");
			}
			String hexByte = Integer.toHexString(bytes.get(i) & 0xFF)
					.toUpperCase();
			sb.append((hexByte.length() == 1 ? "0" + hexByte : hexByte) + " ");
		}
		return sb.toString();
	}

	public String addressString(String address) {
		StringBuilder sb = new StringBuilder();
		for (int i = 0; i < (4 - address.length()); i++) {
			sb.append("0");
		}
		return sb.toString() + address;
	}

	public String getLines() {
		StringBuilder sb = new StringBuilder();
		for (String s : lines) {
			sb.append(s + "\n");
		}
		return sb.toString();
	}

	public String getLabels() {
		StringBuilder sb = new StringBuilder();
		Collection<Integer> value = labels.values();
		Set<String> keys = labels.keySet();
		Iterator<Integer> i = value.iterator();
		Iterator<String> ii = keys.iterator();
		while (i.hasNext()) {
			sb.append(ii.next() + " " + Integer.toHexString(i.next()));
		}
		return sb.toString();
	}

}
