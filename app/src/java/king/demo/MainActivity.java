package king.demo;

import android.app.Activity;
import android.os.Bundle;
import android.content.Context;
import android.widget.Button;
import android.widget.Toast;
import android.view.View;
import android.view.View.OnClickListener;

public class MainActivity extends Activity
{
    private Context context;
    private Button showBt;
    private String message;
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
	context=this;
	showBt=(Button)findViewById(R.id.show);
	showBt.setOnClickListener(new OnClickListener(){
	      @Override
              public void onClick(View view) {
		 message=getNativeMessage();
                 Toast.makeText(context,message,Toast.LENGTH_SHORT).show();
              }
	});
    }

    private String getNativeMessage(){
         String str=Native.sendJavaMessage();
         return str;
    }
}
