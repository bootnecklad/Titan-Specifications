package com.fc.titanassemble;

import java.io.IOException;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

public class TitanAssemblerActivity extends Activity {
	private static final int REQUEST_SAVE = 0;
	private String currentFileName ="No File";
	private TextView currentFileLabel;

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);

		final Button open = (Button) findViewById(R.id.button1);
		final Button assemble = (Button) findViewById(R.id.button2);
		currentFileLabel = (TextView) findViewById (R.id.currentFileLabel);
		final TextView console = (TextView) findViewById(R.id.textView1);
		final EditText address = (EditText) findViewById(R.id.address);
		final EditText width = (EditText) findViewById(R.id.outputwidth);
		open.setOnClickListener(new OnClickListener() {

			public void onClick(View view) {
				openFileDialog();
				try {
					currentFileLabel.setText(currentFileName);
				} catch(Exception e) {
					
				}
			}

		});
		assemble.setOnClickListener(new OnClickListener() {

			public void onClick(View view) {
				console.setText("");
				try {
					int addressStart = 0;
					int outputWidth = 16;

					try {
						addressStart = Integer.parseInt(address.getText()
								.toString());
					} catch (Exception e) {}
					try {
					outputWidth = Integer.parseInt(width.getText()
							.toString());
					} catch(Exception e) {}

					Assembler asm = new Assembler(currentFileName);
					asm.readLines(addressStart);
					asm.assembleLines();
					console.setText(asm.getBytes(outputWidth));
				} catch (IOException ioe) {
					ioe.printStackTrace();
				}
			}

		});

	}

	public void openFileDialog() {
		Intent intent = new Intent(getBaseContext(), FileDialog.class);
		intent.putExtra(FileDialog.START_PATH, "/sdcard");
		intent.putExtra(FileDialog.SELECTION_MODE, SelectionMode.MODE_OPEN);

		// can user select directories or not
		intent.putExtra(FileDialog.CAN_SELECT_DIR, true);

		startActivityForResult(intent, REQUEST_SAVE);
	}

	public synchronized void onActivityResult(final int requestCode,
			int resultCode, final Intent data) {

		if (resultCode == Activity.RESULT_OK) {
			currentFileName = data.getStringExtra(FileDialog.RESULT_PATH);
			currentFileLabel.setText(currentFileName);
			
		} else if (resultCode == Activity.RESULT_CANCELED) {

		}

	}
}