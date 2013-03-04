/*
 * Copyright (C) 2012 OUYA, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package tv.ouya.controllertest;

import android.app.Activity;
import android.os.Bundle;
import android.view.*;
import tv.ouya.console.api.OuyaController;

public class ControllerTestActivity extends Activity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        OuyaController.init(this);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        View controllerView = getControllerView(event);
        controllerView.setVisibility(View.VISIBLE);
        return controllerView.onKeyDown(keyCode,  event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        View controllerView = getControllerView(event);
        controllerView.setVisibility(View.VISIBLE);
        return controllerView.onKeyUp(keyCode,  event);
    }

    @Override
    public boolean onGenericMotionEvent(MotionEvent event) {
        if((event.getSource() & InputDevice.SOURCE_CLASS_JOYSTICK) == 0){
            //Not a joystick movement, so ignore it.
            return false;
        }
        View controllerView = getControllerView(event);
        controllerView.setVisibility(View.VISIBLE);
        return controllerView.onGenericMotionEvent(event);
    }

    private View getControllerView(InputEvent event) {
        View result = null;
        int playerNum = OuyaController.getPlayerNumByDeviceId(event.getDeviceId());
        switch(playerNum) {
            default:
            case 0:
                result = findViewById(R.id.controllerView1);
                break;
            case 1:
                result = findViewById(R.id.controllerView2);
                break;
            case 2:
                result = findViewById(R.id.controllerView3);
                break;
            case 3:
                result = findViewById(R.id.controllerView4);
                break;
        }
        return result;
    }
}
