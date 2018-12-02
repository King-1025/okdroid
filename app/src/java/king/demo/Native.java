package king.demo;

public class Native{
 
    native public static String exec(String command);

    static {
     
	    System.loadLibrary("core");

    }
}
