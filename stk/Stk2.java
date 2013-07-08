/*
 * @(#)Stk.java 1.0 03/04/24
 *
 * You can modify the template of this file in the
 * directory ..\JCreator\Templates\Template_2\Project_Name.java
 *
 * You can also create your own project template by making a new
 * folder in the directory ..\JCreator\Template\. Use the other
 * templates as examples.
 *
 */

 import java.awt.*;
 import java.awt.event.*;
 import java.applet.*;
 import java.lang.Math;
 import javax.swing.*;
 import javax.swing.border.*;
        
 public class Stk2 extends Applet {

     private Image knight, deadKnight, displayKnight, displayArcher, deadArcher, archer;
     private AudioClip hitSound, startSound,knightHitSound;
     Thread thread=null;
     private boolean threadStop=true;
     private Color backGround = null;
     JPanel controlArea = null;
     Game game = null;
     Score scoreArea = null;
     Difficulty difficultyArea = null;
     private boolean bSound = true;
     private JCheckBox soundCheck = null;
     
     // default constents for the class
     
     private int xInc = 1;
     private int yInc = 1;
     private int sleepTime = 5;
     private int maxSleeptime = 10;
            
     public void init() {
     	 MediaTracker tracker = new MediaTracker(this);
         hitSound = getAudioClip(getDocumentBase(),"ni.wav");
         knightHitSound = getAudioClip(getDocumentBase(),"ni.wav");
         startSound = getAudioClip(getDocumentBase(),"sword.wav");
         knight = getImage(getDocumentBase(), "knight.jpg");
         deadKnight = getImage(getDocumentBase(), "deadknight.jpg");
         archer = getImage(getDocumentBase(), "xbow.jpg");
         deadArcher = getImage(getDocumentBase(), "deadxbow.jpg");
         tracker.addImage(knight,0);
         tracker.addImage(deadKnight,0);
         tracker.addImage(archer,0);
         tracker.addImage(deadArcher,0);
         try {
             tracker.waitForID(0);
         } catch (Exception e) {}
		 
         
     	 Color backGround = Color.green.darker().darker();    
     	 Color foreGround = Color.yellow;
         this.setBackground(backGround);
         
         // get parameters if set.
         String xIncParam = getParameter ("xInc");
         String yIncParam = getParameter ("yInc");
         String diffParam = getParameter ("difficulty");
         
         if (xIncParam != null) {xInc = Integer.parseInt(xIncParam);}
         if (yIncParam != null) {yInc = Integer.parseInt(yIncParam);}
         if (diffParam != null) {sleepTime = Integer.parseInt(diffParam);}
         if (sleepTime > maxSleeptime) {sleepTime = maxSleeptime;}
         if (sleepTime < 1 ) {sleepTime = 1;}
         
         // set up window components

         // Button Panel
         JButton goButton = new JButton ("Start run..");
         goButton.addActionListener (new ActionListener() {
         	public void actionPerformed(ActionEvent ae) {
         		game.start();
         		}	
            }
      	 );

         soundCheck = new JCheckBox("Sound", true);
         soundCheck.setBackground(backGround);
         soundCheck.setForeground(foreGround);
         soundCheck.addActionListener (new ActionListener() {
         	public void actionPerformed(ActionEvent ae) {
         		if (soundCheck.isSelected())
         		{
         			bSound = true;
         		}
         		else
         		{
         			bSound = false;
         		}
         	
         		}	
            }
      	 );
         
         JPanel ButtonArea = new JPanel( new GridLayout(2,1));
         ButtonArea.setBackground(backGround);
         ButtonArea.add(soundCheck);
         ButtonArea.add(goButton);
       
       	 Border etch = BorderFactory.createEtchedBorder();
	     ButtonArea.setBorder (BorderFactory.createTitledBorder(etch,"Controls",
	         					TitledBorder.DEFAULT_JUSTIFICATION ,
	         					TitledBorder.DEFAULT_POSITION,
	         					getFont(),
	         					foreGround));

       
         // Difficulty panel
         difficultyArea = new Difficulty(sleepTime,maxSleeptime,foreGround,backGround);
         difficultyArea.setVisible(true);
                  
         // Score Panel
         scoreArea = new Score (foreGround,backGround);
         scoreArea.setVisible(true);
         
         // Control Area
         controlArea = new JPanel(new GridBagLayout());
         GridBagConstraints Con = new GridBagConstraints();
         controlArea.setBackground(backGround);
      
         Con.gridx=0;
         Con.gridy=1;
         Con.fill = GridBagConstraints.NONE;
         Con.anchor = GridBagConstraints.WEST;
         controlArea.add (ButtonArea, Con);
         
         Con.gridx=0;
         Con.gridy=2;
         //Con.fill = GridBagConstraints.HORIZONTAL;
         Con.anchor = GridBagConstraints.NORTHWEST;
         controlArea.add (difficultyArea, Con);
         
         Con.gridx=0;
         Con.gridy=3;
         Con.fill = GridBagConstraints.NONE;
         controlArea.add (scoreArea, Con);
      
         
         // Game area
         game = new Game(); 
         
         // Complete Applet
         setLayout(new FlowLayout(FlowLayout.LEFT));
         this.add (controlArea);
         this.add (game);
      
        
     }
	 
     public void start() {
          game.initGame();
          scoreArea.clear();
     }


     public void stop() {
      	 threadStop = true;
      	 if (thread != null) {
      	 	thread.interrupt(); 
      	 }    	
     
   	 } // class.Stk2
   	 
   		
	/************************************/
	/* Inner class to handle game panel	*/
	/************************************/
	class Game extends JComponent implements MouseListener, Runnable {
        
	    private int archerHeight, archerWidth, deadArcherHeight, deadArcherWidth, deadKnightWidth, deadKnightHeight;
     	private int imageWidth,imageHeight;
        private int knightX,knightY, archerX, archerY;
     	private int winXSize = 0;
     	private int winYSize = 0;
     	private int maxKnightX ;
     	private int maxKnightY ;
 	    private boolean goingRight=false;
     	private int zagCount=0, maxZag=0;

		public Game()
		{

				addMouseListener(this);
				initGame();
				//setVisible(true);
				
	         	imageWidth = knight.getWidth(this);
         		imageHeight = knight.getHeight(this);
         		archerWidth = archer.getWidth(this);
         		archerHeight = archer.getHeight(this);
         		deadArcherWidth = deadArcher.getWidth(this);
         		deadArcherHeight = deadArcher.getHeight(this);
         		deadKnightWidth = deadKnight.getWidth(this);
         		deadKnightHeight = deadKnight.getHeight(this);

		}
		
		public Dimension getPreferredSize() {
			return new Dimension(Stk2.this.getSize().width-controlArea.getSize().width-10, 
								 Stk2.this.getSize().height);
		}
		
		public void paint(Graphics g) {
     	 
     	 g.setColor (Color.black);
     	 g.drawRect (5,5,winXSize-10, winYSize-10);
     	 g.drawRect (6,6,winXSize-12, winYSize-12);
         g.drawImage(displayKnight,knightX, knightY,this);
         g.drawImage(displayArcher,archerX, archerY,this);
     	}
     	
     	// Mouse click handler - Starts game if on Archer
     	public void mouseClicked(MouseEvent e) { 
     	int mouseX = e.getX();
        int mouseY = e.getY();
     	     	
     	// game starts with click on archer
     	if (threadStop == true &&
            (mouseX >= archerX && mouseX <= archerX+archerWidth) &&
            (mouseY >= archerY && mouseY <= archerY+archerHeight)) {
			start();    		
     	}
  	 }
  	 
  	 // start a run
  	 public void start() {
  	 	
    		initGame();
   		        	
         	// create thread for animation
         	thread = new Thread(this);
         	
      	 	thread.setPriority(Thread.NORM_PRIORITY-2);
         	thread.start();	
  	 	
  	 }
     
     public void mouseReleased(MouseEvent e) { }
     public void mouseExited(MouseEvent e) { }
     public void mouseEntered(MouseEvent e) { }

	// Mouse pressed handler - Provides archer hit detection
     public void mousePressed(MouseEvent e) {
         int mouseX = e.getX();
         int mouseY = e.getY();
	   		 
         if (threadStop == false &&
             (mouseX >= knightX && mouseX <= knightX+imageWidth) &&
             (mouseY >= knightY && mouseY <= knightY+imageHeight)) {
                 if (bSound) knightHitSound.play();
                 // A hit 
                 threadStop=true;
                 thread.interrupt();
                 displayKnight = deadKnight; // switch image to dead knight
                 // shift dead knight left to fit window
                 if (knightX > winXSize - deadKnightWidth)
                 {
                 	knightX -= deadKnightWidth;
                 }
                 scoreArea.incArcherScore();
                 repaint();
          }

      }
     
    // Thread run method - performs animation and knight win detection    
	public void run () {
		
     	// Move the knight in zig zag style
     	showStatus("Shoot The Knight");
        repaint();
		
		// brief pause to get ready, and show repainted positions to user	
		try {
        	Thread.sleep(1000);
        } catch (Exception ex) {} 	         	
		threadStop = false;
		
     	if (bSound) startSound.play();
    	while (threadStop == false) {
    		int oldX = knightX;
    		int oldY = knightY;
    		
        	knightY = (knightY+yInc) % maxKnightY;
            if ( knightY >= maxKnightY-yInc )
        	{
        		// Knight has reached archer, so archer dies
        		displayArcher = deadArcher; // switch image to dead archer
        		archerY = winYSize-deadArcherHeight - 7 ;
        		threadStop = true;
        		// move knight next to archer
        		knightX = archerX + deadArcherWidth/2 - imageWidth/2;
        		knightY = archerY-imageHeight-10;
        		
        		repaint();
        		if (bSound) hitSound.play();
				scoreArea.incKnightScore();
        	} 
        	else
        	{
        		// Reverse direction of knight if its time, or have hit the edge
        		if (zagCount-- <= 0 ||
        		    (goingRight && knightX >= maxKnightX - xInc) ||
        		    (!goingRight && knightX <= xInc ))
        		{
        			
        			// its time to switch dir
        			if (goingRight == true) 
        				goingRight = false;
        			else
        				goingRight = true;
        			
        			// work out how long to go this way
        			zagCount = getZagCount();
        		}
        	
				// move the knight left or right by the increment        			
        		if (goingRight ) {
        		    knightX += xInc;
        		} else
        			knightX -= xInc;
        		}
        
        		// just repaint the knight, nothing else has changed  
        		this.repaint(oldX - xInc, oldY, imageWidth+xInc, imageHeight+yInc);	
        		try {
        			Thread.sleep(sleepTime);
        		} catch (Exception e) {}
        	}
       	} 
       	
   	// method to initialise for new game   
	public void initGame() {
	 	
	 	winXSize = getSize().width;
		winYSize = getSize().height;
        maxKnightX = winXSize - imageWidth ;
        maxKnightY = winYSize - imageHeight - archerHeight;
  		sleepTime = difficultyArea.getDifficulty();
  				
   		// start knight at the top 
       	knightX = (int)(Math.random() * maxKnightX);
       	knightY = 30;  
       	
        archerX = winXSize/2;
       	archerY = winYSize-archerHeight - 7;
     	maxZag = winXSize/xInc;    
     	
   	    // set intial images
	    displayKnight = knight;
    	displayArcher = archer;
    	
       	// set initial direction
       	if (Math.random() < 0.5 ) { 
	       	goingRight = true; 
        } else	{ 
	       	goingRight = false;
        }
        zagCount = getZagCount(); // work out how long to go this way
	}
	
    // Method to get time for knight to keep going in the current direction
    private int getZagCount ()
    {
    	return (int)(Math.random()*maxZag); 
    }

	} // class Game
	
	/*****************************************/
	/* Inner Class to handle difficulty area */
	/*****************************************/
	class Difficulty extends JPanel {
		
		private int diff;
        private JTextField difText = null;
        private int max;
        
		public Difficulty (int start, int maxDiff, Color foreGround, Color backGround ) {
			
			 diff = start;
			 max = maxDiff;
			 JButton upButton = new JButton ("+");
	         JButton downButton = new JButton ("-");
	         difText = new JTextField(Integer.toString(diff),2); 
	         difText.setEditable(false);
	         
	         setLayout( new GridLayout(1,3));
	         setBackground(backGround);
	         setForeground(foreGround);
	         
	         Border etch = BorderFactory.createEtchedBorder();
	         setBorder (BorderFactory.createTitledBorder(etch,"Difficulty (1-"+ max + ")",
	         											 TitledBorder.DEFAULT_JUSTIFICATION ,
	         											 TitledBorder.DEFAULT_POSITION,
	         											 getFont(),
	         											 foreGround));
	                          
	         add (upButton);
	         add (downButton);
	         add (difText);
	         
   	         upButton.setActionCommand("Up");
    	     upButton.addActionListener (new ActionListener() {
        	 	public void actionPerformed(ActionEvent ae) {
         			if ( diff < max ) {diff++;}
	         	    difText.setText(Integer.toString(diff)); 
	         	    }
         		}
       		);
       		
       		 downButton.setActionCommand("Down");
    	     downButton.addActionListener (new ActionListener() {
        	 	public void actionPerformed(ActionEvent ae) {
         			if (diff > 1) { diff--; }
	         	    difText.setText(Integer.toString(diff)); 
         			}
         		}
       		);
       		
       		setVisible(true);
		}
		
		public int getDifficulty()
		{
			return diff;
		}
	}
	
	
	/************************************/
	/* inner class to handle score area */
	/************************************/
	class Score extends JPanel {
		private int archerScore;
		private int knightScore;
		private JTextField archerScoreT = null, knightScoreT = null;
		private JPanel scorePanel = null;
		
		public Score (Color foreGround, Color backGround) {
			
			archerScore = 0;
			knightScore = 0;
			 
			 JLabel knightScoreL = new JLabel("KNIGHT:");
	         knightScoreL.setForeground(foreGround);
	         JLabel archerScoreL = new JLabel("ARCHER:");
	         archerScoreL.setForeground(foreGround);
	         
	         knightScoreT = new JTextField("0",3);
	         knightScoreT.setEditable(false);
	         archerScoreT = new JTextField("0",3);
			 archerScoreT.setEditable(false);
			 
			 JButton clearButton = new JButton ("clear");
			 
	         setLayout( new GridLayout(3,2));
			 setBackground(backGround);
	         setForeground(foreGround);
	         	
	         Border etch = BorderFactory.createEtchedBorder();
	         setBorder (BorderFactory.createTitledBorder(etch,"Score",
	         											 TitledBorder.DEFAULT_JUSTIFICATION ,
	         											 TitledBorder.DEFAULT_POSITION,
	         											 getFont(),
	         											 foreGround));
	         
	         add (knightScoreL);
	         add (knightScoreT);
	         add (archerScoreL);
	         add (archerScoreT);
	         add (clearButton);
	         	         
	         //Button handler
	         clearButton.setActionCommand("Clear");
    	     clearButton.addActionListener (new ActionListener() {
        	 	public void actionPerformed(ActionEvent ae) {
         			clear();
         			}
         		}
       		);
       		setVisible(true);
       		
		}
		
		private void displayScore()
		{
			  archerScoreT.setText(Integer.toString(archerScore)) ;
			  knightScoreT.setText(Integer.toString(knightScore)) ;
		}
		
		public void incArcherScore()
		{
			archerScore++;
			displayScore();
		}

		public void incKnightScore()
		{
			knightScore++;
			displayScore();
		}
		
		public void clear()
		{
			knightScore = 0;
			archerScore = 0;
			displayScore();
		}
			
	}
}

 