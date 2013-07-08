package com.dethorpe.guestbook;

import java.io.*;
import java.util.HashMap;
import java.util.StringTokenizer;

class gbFile {
	
	private String msgKey = "message"; // key for message form field
	private String dateKey = "date"; // key for date field
	private HashMap hm = null;
	
	public gbFile(String gbFile) throws Exception
	{
		File gb = new File(gbFile);
		processFile(gb);
		gb = null; 
	}

	public gbFile(String gbDir, String gbFile) throws Exception
	{
		File gb = new File(gbDir + "/" + gbFile);
		processFile(gb);
		gb = null; 
	}

	public gbFile(File gbFile) throws Exception
	{
		File gb = gbFile;
		processFile(gb);
		gb = null; 
	}

	private void processFile(File gb) throws Exception
	{
       	// extract data from file
       	BufferedReader in = new BufferedReader(new FileReader (gb));
       	String msgDate,line;
		hm = new HashMap();
       	
       	while ((line = in.readLine()) != null)
       	{
       		if (line.startsWith("--------------"))
       			break; // reached the start of the actual form fields
       		if (line.startsWith("Date:"))
       		{
       			// date is on next line
       			// line = in.readLine();
       			System.out.println( "Found date line: " + line);
       			// its the sent date line format is:
       			//  Sent: Sun, 28 May 2003 22:11
       			hm.put (dateKey,line.substring(11));
       			System.out.println( "Found date: " + hm.get(dateKey));
       		}
       	}
       	
       	// Now loop through the form fields
       	String key=null;
       	String value=null;
       	int lines =0;
       	boolean bReadingMsg = false;
       	
       	while ((line = in.readLine()) != null)
       	{
       		if (line.startsWith("-------------"))
       			break; // reached the end of the actual form fields
       		
       		// each field is colon seperated
       		StringTokenizer st = new StringTokenizer(line,":");
       		if (st.hasMoreTokens())
       		{
       			key = st.nextToken(); // 1st field is key 
       			if (st.hasMoreTokens())
       				value = st.nextToken(); // 2nd field is value
       			else
       			 	value = null;
       		}
       		else // no tokens so must be blank line
       		{
       			// key stays at last value
				value = null;
				// only allow blank lines in message, skip otherwise
				if (!bReadingMsg)
				{
					continue; 
				}
       		}
       		
       		if (key.equals("B1")) 
       			bReadingMsg = false; // reached end of message
       		
       		if (bReadingMsg)
       		{
       			if (lines > 10 )
       			{
       				// msg to big so abort and skip the file
       				throw new Exception ("ERROR: Message has too many lines, limit is 10");
       			}
       			String msg = (String)hm.get(msgKey);
       			// concatenating message lines
       			msg += ("\n" + line) ;
       			hm.put(msgKey, msg);
       			lines++;
       		}
       		else 
       		{
       			if (key.equals(msgKey))
       			{
       				lines = 1;
       				bReadingMsg = true;
       			}
       			
       			// set key value in hash map
       			System.out.println ("Storing key [" + key + "] value [" + value + "]");
       			hm.put(key,value);
       		}	
       	}
       	
       	in.close();
  	}


	/*
	 * method to read in a file and extract the form fields
	 * Returns hashmap with key value pairs representing the form fields
	 */
	public HashMap getFormFields()
	{
       	return hm;
	}
}

