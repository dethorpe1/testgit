package com.dethorpe.guestbook;

import java.io.*;

class gbFilter implements FilenameFilter{

// guestbook filenames are of form 'BPAS WWW Form Submission*.eml'

private String gbExtension = ".eml"; // default extension

public boolean accept(File dir, String name)
{
	System.out.print("Checking file: " + dir + "/" + name + ". Against : " + gbExtension);
	if (name.endsWith(gbExtension))
	{
		return true;
	}
	else
	{
		return false;
	}
}

public void setGbExtension(String e)
{
	gbExtension = e;
}


}