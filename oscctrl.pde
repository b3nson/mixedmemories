import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress remoteui;

boolean save_motionCheckEnabled = motionCheckEnabled;
boolean restartdebounce = false;

void oscEvent(OscMessage theOscMessage) {
  //print(" addrpattern: "+theOscMessage.addrPattern());
  //print(" typetag: "+theOscMessage.typetag());
  //println(" value: "+theOscMessage.get(0).floatValue());
  
  if(theOscMessage.checkAddrPattern("/shader")==true) {
    updateRemoteUi();   
    return;
  } else if(theOscMessage.checkAddrPattern("/mm")==true) {
    updateRemoteUi();   
    return;
  }   
  
  float val = theOscMessage.get(0).floatValue();
  
  if(theOscMessage.checkAddrPattern("/mm/slideshow")==true) {
    if(val == 1.0) {
      captureMode = false;
     } else {
      captureMode = true;
     }
     
     countNoMotion = -1;

      if(!captureMode) {
        //motionCheckEnabled = false;
        slideShowForced = true;
        startSlideshow();  //<>// //<>//
      } else {
        //motionCheckEnabled = true;
        slideShowForced = false;
        //pauseMotionCheck();
        endSlideshow(); 
      }
  } else if(theOscMessage.checkAddrPattern("/mm/slidedur")==true) {
      slideDuration = val;
      println("OSC: setSlideDuration: " +val);
  } else if(theOscMessage.checkAddrPattern("/mm/fadeduration")==true) {
      transDuration = val;
      println("OSC: setFadeDuration: " +val);
  } else if(theOscMessage.checkAddrPattern("/mm/durationdefault")==true) {
      transDuration = 2f;
      slideDuration = 5f;
      updateRemoteUi();
      println("OSC: resetSlideDurations: " +val);
  } else if(theOscMessage.checkAddrPattern("/mm/switchblack")==true) {
    if(val == 1.0) {
      blackScreen = true;
      save_motionCheckEnabled = motionCheckEnabled;
      motionCheckEnabled = false;
    } else {
      blackScreen = false;
      motionCheckEnabled = save_motionCheckEnabled;  
      if(motionCheckEnabled) pauseMotionCheck();
    }
  } else if(theOscMessage.checkAddrPattern("/mm/modect_toggle")==true) {
        if(val == 1.0) {
          motionCheckEnabled = true;
          pauseMotionCheck();
        } else {
          motionCheckEnabled = false;
        }
      
  } else if(theOscMessage.checkAddrPattern("/mm/modect_preview")==true) {
        if(val == 1.0) {
          modect_preview = true;
        } else {
          modect_preview = false;
        }
  } else if(theOscMessage.checkAddrPattern("/mm/modect_contrast")==true) {
        modect_contrast = val;  
  } else if(theOscMessage.checkAddrPattern("/mm/capturehidden")==true) {
        captureSecret = true;  
  } else if(theOscMessage.checkAddrPattern("/mm/fullscreen")==true) {
        //fullscreen = !fullscreen;  
  } else if(theOscMessage.checkAddrPattern("/mm/kill")==true) {
        exit();
  } else if(theOscMessage.checkAddrPattern("/mm/restart")==true) {
    if(!restartdebounce) {
      restartdebounce = true;
      println("RESTART");
      String[] params = {(sketchPath("") +"restart.sh"), "-a /Applications/Utilities/Terminal.app/" };           
      exec(params);
      exit();
      super.exit();
    }
  } else if(theOscMessage.checkAddrPattern("/shader/instagram/1/1")==true) { //OFF
    if(val == 1.0) {
        instamode = 0;
        shader_brightness = 1.0;
        shader_contrast   = 1.0;
        shader_saturation = 1.0;
        shader_plusr = 1.0;
        shader_plusg = 1.0;
        shader_plusb = 1.0;
        shaderParamChanged = true;
        updateRemoteUi();
    }
  }else if(theOscMessage.checkAddrPattern("/shader/instagram/2/1")==true) {  //EARLYBIRD
    if(val == 1.0) {
        instamode = 1;
        shader_brightness = 1.2;
        shader_contrast   = 1.1;
        shader_saturation = 1.2;
        shader_plusr = 1.07;
        shader_plusg = 1.02;
        shader_plusb = 0.8;
        instamix = 0.8;
        shaderParamChanged = true;
        updateRemoteUi();
      }
  }else if(theOscMessage.checkAddrPattern("/shader/instagram/3/1")==true) {  //AMARO
    if(val == 1.0) {
        instamode = 2;
        shader_brightness = 1.1;
        shader_contrast   = 1.1;
        shader_saturation = 1.1;
        shader_plusr = 1.0;
        shader_plusg = 1.0;
        shader_plusb = 1.03;
        instamix = 0.6;
        shaderParamChanged = true;
        updateRemoteUi();
      }
  }else if(theOscMessage.checkAddrPattern("/shader/instagram/4/1")==true) {  //XPRO
    if(val == 1.0) {
        instamode = 3;
        shader_brightness = 1.2;
        shader_contrast   = 1.0;
        shader_saturation = 1.3;
        shader_plusr = 1.0;
        shader_plusg = 1.0;
        shader_plusb = 1.0;
        instamix = 0.7;
        shaderParamChanged = true;
        updateRemoteUi();
      }
  } else if(theOscMessage.checkAddrPattern("/shader/instamix")==true) {
    instamix = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/shader/threshold")==true) {
    threshold = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/shader/brightness")==true) {
    shader_brightness = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/shader/contrast")==true) {
    shader_contrast = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/shader/saturation")==true) {
    shader_saturation = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/shader/plusr")==true) {
    shader_plusr = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/shader/plusg")==true) {
    shader_plusg = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/shader/plusb")==true) {
    shader_plusb = val;
    shaderParamChanged = true;
  } else if(theOscMessage.checkAddrPattern("/mm/showfps")==true) {
    if(val == 1.0) {
      showfps = true;
    } else {
      showfps= false;
    }
 } else if(theOscMessage.checkAddrPattern("/shader/writesettings")==true) {
   println("writesettings");
   writeShaderSettingsToFile();
 } else if(theOscMessage.checkAddrPattern("/shader/readsettings")==true) {
   println("readsettings");
   readShaderSettingsFromFile();   
 } else if(theOscMessage.checkAddrPattern("/shader/updateui")==true) {
   println("updateui");
   updateRemoteUi();   
 }

 
  
}

public void writeShaderSettingsToFile() {
  String[] list = new String[8];
  list[0] = str(instamode);
  list[1] = str(instamix);
  list[2] = str(shader_brightness);
  list[3] = str(shader_contrast);
  list[4] = str(shader_saturation);
  list[5] = str(shader_plusr);
  list[6] = str(shader_plusg);
  list[7] = str(shader_plusb);
  
  saveStrings(shaderSettingsPath, list);
}

public void readShaderSettingsFromFile() {
  String[] list = loadStrings(shaderSettingsPath);

  instamode = int(list[0]);
  instamix = float(list[1]);
  shader_brightness = float(list[2]);
  shader_contrast = float(list[3]);
  shader_saturation = float(list[4]);
  shader_plusr = float(list[5]);
  shader_plusg = float(list[6]);
  shader_plusb = float(list[7]);
  
  shaderParamChanged = true;
  updateRemoteUi();
}


public void updateRemoteUi() {
   OscBundle msgbundle = new OscBundle();

   OscMessage msg = new OscMessage("/mm/showfps"); 
   msg.add(float(int(showfps)));
   msgbundle.add(msg);
   msg.clear();

   msg.setAddrPattern("/mm/switchblack");
   msg.add(float(int(blackScreen)));
   msgbundle.add(msg);
   msg.clear();

   msg.setAddrPattern("/mm/slideshow");
   msg.add(float(int(!captureMode)));
   msgbundle.add(msg);
   msg.clear();

   msg.setAddrPattern("/mm/slidedur");
   msg.add(slideDuration);
   msgbundle.add(msg);
   msg.clear();
   
   msg.setAddrPattern("/mm/fadeduration");
   msg.add(transDuration);
   msgbundle.add(msg);
   msg.clear();   

   msg.setAddrPattern("/mm/modect_toggle");
   msg.add(float(int(motionCheckEnabled)));
   msgbundle.add(msg);
   msg.clear();
   
   msg.setAddrPattern("/mm/modect_preview");
   msg.add(float(int(modect_preview)));
   msgbundle.add(msg);
   msg.clear();

   msg.setAddrPattern("/mm/modect_contrast");
   msg.add(modect_contrast);
   msgbundle.add(msg);
   msg.clear();  
   
   msg.setAddrPattern("/shader/plusr");
   msg.add(shader_plusr);
   msgbundle.add(msg);
   msg.clear();
   
   msg.setAddrPattern("/shader/plusg");
   msg.add(shader_plusg);
   msgbundle.add(msg);
   msg.clear();

   msg.setAddrPattern("/shader/plusb");
   msg.add(shader_plusb);
   msgbundle.add(msg);
   msg.clear();
   
   msg.setAddrPattern("/shader/brightness");
   msg.add(shader_brightness);
   msgbundle.add(msg);
   msg.clear();
   
   msg.setAddrPattern("/shader/contrast");
   msg.add(shader_contrast);
   msgbundle.add(msg);
   msg.clear();
   
   msg.setAddrPattern("/shader/saturation");
   msg.add(shader_saturation);
   msgbundle.add(msg);
   msg.clear();

   msg.setAddrPattern("/shader/instamix");
   msg.add(instamix);
   msgbundle.add(msg);
   msg.clear();
   
   String tmp = "/shader/instagram/" +(instamode+1) +"/1";
   msg.setAddrPattern(tmp);
   msg.add(1.0);
   msgbundle.add(msg);
   msg.clear();      
   
   if(startOSC) {
     osc.send(msgbundle, remoteui); 
   }
}