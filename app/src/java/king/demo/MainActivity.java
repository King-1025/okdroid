package king.demo;

import android.app.Activity;
import android.os.Bundle;
import android.content.Context;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import android.view.View;
import android.view.View.OnClickListener;

public class MainActivity extends Activity
{
    private Context context;
    private Button showBt;
    private EditText inputEd;
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
	context=this;
	showBt=(Button)findViewById(R.id.show);
	inputEd=(EditText)findViewById(R.id.input);
	showBt.setOnClickListener(new OnClickListener(){
	      @Override
              public void onClick(View view) {
 		 String message=Native.exec(" "+inputEd.getText());
                 Toast.makeText(context,message,Toast.LENGTH_SHORT).show();
              }
	});
    }
}
