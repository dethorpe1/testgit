/*
 * @(#)Guestbook.java 1.0 03/05/29
 *
 * You can modify the template of this file in the
 * directory ..\JCreator\Templates\Template_1\Project_Name.java
 *
 * You can also create your own project template by making a new
 * folder in the directory ..\JCreator\Template\. Use the other
 * templates as examples.
 *
 */
package com.dethorpe.guestbook;

import java.sql.*;
import java.io.*;
import java.util.HashMap;
import java.text.*;
//import gbFilter.*;


class Guestbook {

    static String url = "jdbc:odbc:BPASMembership";	
    static private PreparedStatement stmt = null;    
 
    /* 
     * Method to log SQL exceptions
     */
	private static void logSqlException(SQLException ex)
	{
		System.out.println("\n--- SQLException caught ---\n");
		while (ex != null) {
			System.out.println("Message:   "
        	                           + ex.getMessage ());
			System.out.println("SQLState:  "
        	                           + ex.getSQLState ());
			System.out.println("ErrorCode: "
        	                           + ex.getErrorCode ());
			ex = ex.getNextException();
			System.out.println("");
		}
	}

	/*
	 * Method to set an indicator field bind variable
	 */
	public static void setIndicator(String ind, int field) throws SQLException
	{
		if (ind == null || ind.equals("NO"))
			stmt.setInt(field,0);
		else
			stmt.setInt(field,1);
	}
	
	/*
	 * Method to store the guestbook entry fields into a new row in the database
	 */
	public static boolean storeEntry(HashMap hm)
	{
		// Hash map keys
		String dateKey 		= "date";
		String nameKey 		= "realname";
		String emailKey 	= "email";
		String groupNameKey = "groupname";	
		String msgKey 		= "message";
		String groupIndKey 	= "groupcheck";
		String bpasIndKey 	= "membership";
		
		String value;
		
	   // create and execute insert to database
       try {
			// set bind variables
			
			// DATE is mandatory
			value = (String)hm.get(dateKey);
	
			if (value != null)
			{
				DateFormat df = new SimpleDateFormat("dd MMM yyyy HH:mm:ss");
				Timestamp time = new Timestamp(df.parse(value).getTime());
				stmt.setTimestamp(1,time);
				System.out.println("Date is: " + time.toString());
			}
			else
				throw new Exception("Date missing from guestbook data");
	
			// NAME is mandatory
			value = (String)hm.get(nameKey);
	
			if (value != null)
				stmt.setString(2,value);
			else
				throw new Exception("Name missing from guestbook data");
				
			// EMAIL is optional
			stmt.setString(3,(String)hm.get(emailKey));
			
			// OtherGroupInd
			setIndicator((String)hm.get(groupIndKey),4);
		
			// OTHER GROUP is optional
			stmt.setString(5,(String)hm.get(groupNameKey));

			// BpasInd
			setIndicator((String)hm.get(bpasIndKey),6);
				
			// MESSAGE is mandatory
			value = (String)hm.get(msgKey);
	
			if (value != null)
			{
				System.out.println( "About to set Message to : " + value );
				stmt.setAsciiStream(7,new ByteArrayInputStream(value.getBytes()), value.length() );
			}
			else
				throw new Exception("Message missing from guestbook data");
			
			// execute the statement
			System.out.println( "About to execute insert");
			stmt.executeUpdate();
            
        } catch(SQLException ex) {
           	System.err.println("Failed to execute insert");
           	logSqlException(ex);
           	return false;
       	} catch(Exception e) {
           	System.err.println("Failed to insert data");
            System.err.println("Exception: " + e.getMessage());
           	return false;
        }
       	
       	return true;
	}
	
	public static void main(String args[]) {
		System.out.println("Starting Guestbook...");
		
		Connection con = null;
        String insertString;
        insertString = "INSERT INTO Guestbook (MessageDate, Name, email, OtherGroupInd, OtherGroupName, BpasInfoInd, Message) " +
                           "VALUES (?,?,?,?,?,?,?);";
		HashMap hm;
		
		// get guestbook dir from environment
		String gbDirName = System.getProperty("HOME");
		if (gbDirName == null )
		{
		    System.err.println("HOME environment variable not set");
		    System.exit(1);
		}
		else
		{
			gbDirName += "/BPAS/Guestbookmails"; // add rest of path
		}
		
		// Create class for DB connection
        try {
            Class.forName("sun.jdbc.odbc.JdbcOdbcDriver");
        } catch(java.lang.ClassNotFoundException e) {
            System.err.print("ClassNotFoundException: ");
            System.err.println(e.getMessage());
            System.exit(1);
        }

		// Connect to the database
        try {
            con = DriverManager.getConnection(url, "", "");
            System.out.println ("Connected to: " + url);
        } catch(SQLException ex) {
            System.err.println("Failed to Connect to database");
            logSqlException(ex);
            System.exit(1);
        }

       	// Prepare the insert statement
        try {
			stmt = con.prepareStatement(insertString);
	    } catch(SQLException ex) {
           	System.err.println("Failed to prepare insert");
           	logSqlException(ex);
            System.exit(1);
        }
        
        
		// open guestbook directory
        File gbDir = new File(gbDirName);
        
        if (!gbDir.isDirectory())
        {
        	System.err.println (gbDirName + " Is not a directory");
        	System.exit(1);
        }
        
        // Get list of guestbook email files in directory
        String [] gbFiles = gbDir.list(new gbFilter());
        
        // Loop through guestbook mail files
        for ( int i = 0; i < gbFiles.length; i++)
        {
        	System.out.println("Processing File: "+ gbFiles[i]);
        	
        	// Extract the form data from the file
    	    try {
    	    	hm = (new gbFile(gbDirName, gbFiles[i])).getFormFields();
        	} catch (Exception e)
        	{
        		System.out.println ("Failed to extract data from file '" + 
        							 gbFiles[i] +
        							 "' Skipping file.");
        		System.out.println ("   Exception was: " + e.getMessage());
        		continue;
        	}
        	
        	// insert the form data into the database
       		if (!storeEntry (hm))
        	{
        		System.out.println ("Failed to store data from file '" + 
        							 gbFiles[i] +
        							 "' Skipping file.");
        		continue;
        	}
        	
        	// if we get here it worked so remove the file
        	// (production system would archive it)
        	System.out.println("Deleteing File " + gbDirName + "\\" + gbFiles[i]);
        	File df = new File (gbDirName + "\\" + gbFiles[i]);
        	
        	if (!df.delete())
        		System.err.println("Failed to delete file '"+ gbDirName + "\\" + gbFiles[i]);
        }

		// Close the statement and database connection         
        
        try {
        	stmt.close();
            con.close();
        } catch(SQLException ex) {
            System.err.println("Failed to close statement or connection");
            logSqlException(ex);
        }
        
        System.out.println("\n ### Guestbook mails imported to DB, press Enter to exit\n");
        try { 
        int key = System.in.read();
    	}  catch (Exception e) {};
	}
	
}
