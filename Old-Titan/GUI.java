/* _^_ | but i maintain the copyright rights */


import java.applet.Applet;
import java.io.*;

import java.awt.Image;
import java.awt.Color;
import java.awt.Point;
import java.awt.Menu;
import java.awt.MenuItem;
import java.awt.MenuBar;
import java.awt.Graphics;
import java.awt.Dimension;
import java.awt.event.*;
import java.awt.Frame;
import java.awt.FileDialog;

public class GUI extends Applet implements Runnable, ActionListener {

   private static final int WIDTH = 600;
   private static final int HEIGHT = 400;

   private static final int LED_SIZE = 10;

   private static final Point LEDPoints[] = new Point[] {
	new Point(40, 40), new Point(60, 40),				// LED A
	new Point(40, 80), new Point(60, 80),				// LED B
	new Point(40, 120), new Point(60, 120),				// LED C
	new Point(30, 170), new Point(50, 170), new Point(70, 170)	// ALU

   };

   private boolean singleStep;
   private volatile boolean run;
   private String error;
   private CPU cpu;
   private Image bufImg;
   private Graphics bufGfx;

   public static void main(String args[]) {
	DemoFrame df = new DemoFrame("Bootnecklad Relay CPU Emulator by _^_");
	GUI gui = new GUI();
	gui.cpu = new CPU();
	df.app = gui;
	df.setVisible(true);
	df.add(df.app);

	MenuBar mb = new MenuBar();

	Menu file = new Menu("File");

	Menu program = new Menu("Program");

	MenuItem open = new MenuItem("Open");
	MenuItem start = new MenuItem("Start");

	file.add(open);
	program.add(start);

	file.addActionListener(gui);
	program.addActionListener(gui);
	
	mb.add(file);
	mb.add(program);

	df.setMenuBar(mb);
	df.pack();
	df.app.init();
	df.app.start();
   }

   public void actionPerformed(ActionEvent ae) {
	String command = ae.getActionCommand();
	if(command.equals("Open")) {
	   FileDialog fd = null;
	   fd = new FileDialog((Frame)getParent(), "Select a program", fd.LOAD);
	   fd.setVisible(true);
	   String program = fd.getFile();
	   if(program != null) try {
		BufferedReader br = new BufferedReader(new FileReader(program));
		cpu.loadProgram(br);
		br.close();
	   } catch(IOException ioe) {

	   }		
	} else if(command.equals("Start")) {
	   (new Thread(this)).start();
	}
   }

   public void run() {
      if(singleStep) return;

      while(true) {
	   try {
		if(!cpu.execute()) break;
		Thread.sleep(200);
	   } catch(RuntimeException re) {
		error = re.getMessage();
		run = false;
		return;
	   } catch(InterruptedException o) {
	   }

	   renderLEDs(getGraphics());

	}

   }

   public void paint(Graphics g) {
	g.setColor(Color.BLACK);
	g.fillRect(0, 0, WIDTH, HEIGHT);
	renderLEDs(g);
   }

   private void renderLEDs(Graphics g) {
	Point p;
	int mask = 2;
	for(int i = 0; i < 6; i++) {
	   p = LEDPoints[i];
	   g.setColor((cpu.getRegister(1 + (i / 2)) & mask) == 0 ? Color.LIGHT_GRAY : Color.RED);
	   g.fillOval(p.x, p.y, LED_SIZE, LED_SIZE);

	   if((mask >>= 1) == 0) mask = 2;
	}

	int alu = cpu.getALU();
	mask = 4;

	for(int i = 6; i < 9; i++) {
	   p = LEDPoints[i];
	   g.setColor((alu & mask) == 0 ? Color.LIGHT_GRAY : Color.RED);
	   g.fillOval(p.x, p.y, LED_SIZE, LED_SIZE);
	   mask >>= 1;
	}
   }

   public Dimension getPreferredSize() {
	return new Dimension(WIDTH, HEIGHT);
   }

   private static class DemoFrame extends java.awt.Frame {

	private java.applet.Applet app;

	private DemoFrame(String title){
	   super(title);
	   setResizable(false);
	   enableEvents(java.awt.AWTEvent.WINDOW_EVENT_MASK);
	}

	public void processWindowEvent(java.awt.event.WindowEvent we){

	   if(we.getID() == we.WINDOW_CLOSING) {
		if(app != null) app.stop();
		if(app != null) app.destroy();
		dispose();
	   }

	   super.processWindowEvent(we);
	}
   }
}