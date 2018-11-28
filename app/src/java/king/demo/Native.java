package king.demo;

public class Native{
 
    native public static String sendJavaMessage();
  
    static {
      System.loadLibrary("core");
    }
}
