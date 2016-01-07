import java.util.Collections;
import de.looksgood.ani.*;
import processing.video.*;
import java.awt.Frame;

final static int KEYS = 0500;
final static boolean[] keysDown = new boolean[KEYS];
Capture cam;

int w = 1280;//def: 1920
int h = 720;//def: 1080
int preloadnum = 5;
int motionDectInterval = 30; //def: 30
String imgpath = "i/img/";
String oPath = "o/";
String oPathSecret = "o/secret/";
String shaderSettingsPath = "i/conf/shader_settings.conf";
String oscremoteip = "i/conf/osc_settings.conf";
boolean motionCheckEnabled = true;
boolean startOSC = true;
boolean blackScreen = false;
boolean shaderParamChanged = false;
int instamode = 0;
float instamix = 0.5;
float threshold = 0.5;
float shader_brightness = 1.0;
float shader_contrast   = 1.0;
float shader_saturation = 1.0;
float shader_plusr = 1.0;
float shader_plusg = 1.0;
float shader_plusb = 1.0;

boolean fullscreen = false;
boolean animrunning = false;
boolean fadeinrunning = false;
boolean countdownrunning = false;
boolean aftercapturerunning = false;
boolean animsJustStopped = false;
boolean showcapturerunning = false;
boolean captureNow = false;
boolean firstrun = true;
boolean animDir = true;
boolean dirChangePossible = false;
boolean waitforfade = false;
boolean liveimg = false;
boolean captureSecret = false;
boolean captureMode = true;
boolean countdownstopped = false;
boolean showfps = false;
boolean caminitialized = false;

BlendImage[] images;
int ii; //imageindex
int iianim; //imageindex
int iianimoffset = 0; //imageindex
int numanimsrunning = 0;
float fadealpha = 255;
float countdownscale = 0.2;
float countdownfade = 0;
float aftercapturealpha = 255;
float showcapturealpha = 255;
float countdownstroke = 10;
float countdownstoppedscale = 1.0;
int coundownnum = 3;
String timestamp;
color red = color(255, 85, 85);
color green = color(25,180,95);
NetAddress remoteui;

PShader overlay;
PShader blur;
PImage blendImage;
PImage dummy;
PImage capture;
PImage instaimg;
BlendImage fadeimg;
PShape cdsvg, cd1, cd2, cd3, cdx;

AniSequence aniCountdownfade;
Ani aniCountdownscale, aniCountdownstroke, aniAfterCapture, aniShowCapture, delayMotionCheck, aniAlphafade, aniWaitForFade, aniCountdownstopped;


void setup() {
  w = displayWidth;
  h = int(displayWidth / (16f/9f));
  
  w = 720;
  h = int(720 / (16f/9f));
  
  size(1280, 720, P2D);
  //fullScreen(P2D);
  String[] cameras = Capture.list(); //before frameRate
    
  frameRate(120);
  smooth();
  //noCursor();

  Ani.init(this);
  Ani.noAutostart();
  
  if(startOSC) {
    osc = new OscP5(this, 8000);
    remoteui = new NetAddress(loadStrings(oscremoteip)[0], 9000);
  }

  images = getBlendImages();
  ii = (int)(images.length/2);
  dummy = loadImage("i/shader/loading.png");
  instaimg = loadImage("i/shader/filter2.png");
  
  cd1 = loadShape("i/svg/1.svg");
  cd2 = loadShape("i/svg/2.svg");
  cd3 = loadShape("i/svg/3.svg");
  cdx = loadShape("i/svg/x.svg");
  
  diffimg = createGraphics(dectw, decth, P2D);  
  
  preloadNext();
  preloadPrev();
  showNext();

  //println(Capture.list());
  //String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, 640, 480);
  } if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);
    
    cam = new Capture(this, cameras[0]);
    cam.start(); 
  }
  
  readShaderSettingsFromFile();
  initShaders(); 
  
  aniCountdownfade = new AniSequence(this);
  aniCountdownfade.beginSequence();
  aniCountdownfade.add(Ani.to(this, 0.7, "countdownfade", 255, Ani.EXPO_OUT) );
  aniCountdownfade.add(Ani.to(this, 0.2, "countdownfade", 0, Ani.SINE_IN_OUT) );
  aniCountdownfade.endSequence();
  aniCountdownscale = Ani.to(this, 1.0, "countdownscale", 1.0, Ani.LINEAR, "onEnd:runCountdown"); 
  aniCountdownstroke = Ani.to(this, 3.0, "countdownstroke", 50.0, Ani.LINEAR, "onEnd:captureImage"); 
  aniCountdownstopped = Ani.to(this, 1.0, "countdownstoppedscale", 0.4, Ani.BACK_IN, "onEnd:countdownstoppedEnd"); 
  aniAfterCapture = Ani.to(this, 0.3, "aftercapturealpha", 0, Ani.LINEAR, "onEnd:endCaptureImage"); 
  aniShowCapture = Ani.to(this, 0.5, 3, "showcapturealpha", 0, Ani.LINEAR, "onEnd:endShowCapture");
  Ani.noAutostart();
  aniAlphafade = new Ani(this, 0.5, "fadealpha", 0.0, Ani.LINEAR, "onEnd:fadeinFinished");
  aniWaitForFade = new Ani(this, 1.0, "dummyval", 0, Ani.LINEAR, "onEnd:reportAnimFinished");
  if(motionCheckEnabled)
    delayMotionCheck = new Ani(this, checkPauseDuration, "dummyval", 0, Ani.LINEAR, "onEnd:resumeMotionCheck"); 
  
  Ani.autostart();
}

void initShaders() {
  //blur = loadShader("i/shader/blur.glsl");
  overlay = loadShader("i/shader/overlay.glsl");
  overlay.set("alpha", 1.0);
  if(motionCheckEnabled) 
    modect = loadShader("i/shader/modect.glsl");   

  overlay.set("imgSampler", images[ii].getImg());
  overlay.set("camscalex", ( (float)images[ii].getDisplaySize().x) / (float)width);  
  overlay.set("camscaley", ( (float)images[ii].getDisplaySize().y) / (float)height);  
  
  overlay.set("threshold", threshold);
  overlay.set("instamix", instamix);
  overlay.set("instamode", instamode);
  overlay.set("u_Texture1", instaimg);

  overlay.set("T_bright", shader_brightness);
  overlay.set("T_contrast", shader_contrast);
  overlay.set("T_saturation", shader_saturation);  
  
  overlay.set("plusr", shader_plusr);
  overlay.set("plusg", shader_plusg);
  overlay.set("plusb", shader_plusb);
}

void draw() {

  if(!caminitialized) {
    if (cam.available()) {
      cam.read();
      caminitialized = true;
    } else {
      return; 
    }
  }
  
  if(!blackScreen) {
    
    if (cam.available()) {
      cam.read();
    } 
    
    if(!slideShowRunning) {
      background(0,0,0);
            
      if(!waitforfade) {
        shader(overlay);
        overlay.set("camSampler", cam);
        if(shaderParamChanged) {
          overlay.set("instamode", instamode);
          overlay.set("instamix", instamix);
          overlay.set("threshold", threshold);
          overlay.set("T_bright", shader_brightness);
          overlay.set("T_contrast", shader_contrast);
          overlay.set("T_saturation", shader_saturation);  
          overlay.set("plusr", shader_plusr);
          overlay.set("plusg", shader_plusg);
          overlay.set("plusb", shader_plusb);
          shaderParamChanged = false;
        }

        
        pushMatrix();
          translate(0, 0);
          noStroke();
          beginShape(QUAD);
          texture(cam);
          vertex(0, 0, 0, 0);
          vertex(width, 0, 1, 0);
          vertex(width, height, 1, 1);
          vertex(0, height, 0, 1);
          endShape();
        popMatrix();
      }
      
      //=======================================================================================================
      

    
      if(animrunning) {
        
        if(animDir) {
          for(int i = 0; i <= iianimoffset; i++) {
            if(!liveimg || (i != 0)) {
              resetShader();
            } 
            iianim = iigetadd(i);
            images[iianim].draw();  
          }
        } else {
          for(int i = iianimoffset; i >= 0; i--) {
            if(!liveimg || (i != 0)) {
              resetShader();
            }
            iianim = iigetsub(i);
            images[iianim].draw();  
          }          
        }
        
        
      } else {

        images[ii].draw();
      }
      
      //blur.set("blurOffset", 0.001, 0.000);
      //for(int n = 0; n < 2; n++)
      //    filter(blur);
     
     
      if(animsJustStopped) {
        animsJustStopped = false;
        waitforfade = false;
        fadeinrunning = true;
        liveimg = true;
        fadealpha = 255;
    
        overlay.set("imgSampler", images[ii].getImg());
        overlay.set("camscalex", ( (float)images[ii].getDisplaySize().x) / (float)width);  
        overlay.set("camscaley", ( (float)images[ii].getDisplaySize().y) / (float)height); 
        
        aniAlphafade.setBegin(fadealpha);
        aniAlphafade.setEnd(0.0);
        aniAlphafade.start();
        //Ani.to(this, 0.5, "fadealpha", 0.0, Ani.LINEAR, "onEnd:fadeinFinished");
      }
      
      
      if(fadeinrunning) {
       resetShader();
       tint(255, fadealpha);
       images[ii].draw(); 
       noTint();
      }
      
      if(!captureNow) {
        resetShader();
        stroke(red, 255-fadealpha);
        strokeWeight(10);
        noFill();
        rect(0, 0, width, height);
      }

    
      if(countdownrunning) {
        resetShader();
        
        shapeMode(CENTER);
        cdsvg.disableStyle();
        noStroke();
        fill(red, countdownfade);
    
        pushMatrix();
          translate(width/2f, height/2f);
          scale(countdownscale);
          shape(cdsvg, 0, 0);
        popMatrix();
        
       stroke(red);
       strokeWeight(countdownstroke);
       noFill();
       rect(0, 0, width, height);
      }
      
      if(countdownstopped) {
        resetShader();
        resetMatrix();
        shapeMode(CENTER);
        cdx.disableStyle();
        noStroke();
        fill(red);
        pushMatrix();
          translate(width/2f, height/2f);
          scale(countdownstoppedscale);
          shape(cdx, 0, 0);
        popMatrix();
      }
      
      if(aftercapturerunning) {
        resetShader();
        noStroke();
        fill(255, 255, 255, aftercapturealpha);
        rect(0, 0, width, height);
        image(capture, 0, 0);
      }
      
      if(showcapturerunning) {
        resetShader();
        tint(255, showcapturealpha);
        image(capture, width/2, height/2);
        noTint();
        
        stroke(255,255,255, showcapturealpha);
        strokeWeight(50);
        noFill();
        rect(0, 0, width, height);
      }
      
      if(captureSecret) {
        println("*");
        timestamp = generateTimestamp();
        saveFrame(oPathSecret +timestamp +"_mixmem.tif");
        captureSecret = false;
      }
      
      if(captureNow) {
        saveFrame(oPath +timestamp +"_mixmem.tif");
        capture = get();
        captureNow = false;
        aftercapturerunning = true;
        aniAfterCapture.start();
        showcapturerunning = true;
        aniShowCapture.start();
      }
  
    }//if!slideShowRunning
    
    resetShader();
        
    if(motionCheckEnabled) {
      if(countNoMotion <= maxNoMotion) {  
         if(!captureMode && countNoMotion == -1) {
           motionDectInterval = 30;
           captureMode = true;
           endSlideshow(); //<>//
           pauseMotionCheck();
           println("SWITCH MODE TO: captureMode " +countNoMotion);
         }
      } else {
        if(captureMode) {
          motionDectInterval = 15;
          captureMode = false;
          startSlideshow();
          println("SWITCH MODE TO slideshowMode");
        }
      }
    
      if(frameCount % motionDectInterval == 0) {
        if(!motioncheckpaused) {
          checkMotion();
        }
      }

  }//motionCheckEnabled
  //}//cam.available

  if(!captureMode) {
    drawSlideshow();
  } 

  if(modect_preview) {
    image(cam, 400 ,200, 320, 180);
    image(diffimg, 780, 200, 320, 180);
  }

  }//!blackScreen
  else {
    background(0,0,0);  
  }
  
  if(showfps) {
    fill(0);
    text(int(frameRate) +" fps", w-79, h-23);
    text("h - show this help", 49, 49);
    text("SPACE - show this help", 49, 69);    
    text("ENTER - show this help", 49, 89);
    text("LEFT/RIGHT - prev/next memory", 49, 109);
    text("SCROLL - prev/next memory", 49, 129);
    
    fill(255);
    text(int(frameRate) +" fps", w-80, h-24);
    text("h - show this help", 50, 50);
    text("SPACE - show this help", 50, 70);
    text("ENTER - show this help", 50, 90);
    text("LEFT/RIGHT - prev/next memory", 50, 110);
    text("SCROLL - prev/next memory", 50, 130);    
  }
//  frame.setTitle(" " + int(frameRate));
} //draw


// ---------------------------------------------------------------------------
//  ACTIONS
// ---------------------------------------------------------------------------

void pauseMotionCheck() {
  //println("pauseMotionCheck: " +motionCheckEnabled);
  if(motionCheckEnabled) {
    motioncheckpaused = true; 
    //Ani.to(this, checkPauseDuration, "dummyval", 0, Ani.LINEAR, "onEnd:resumeMotionCheck"); 
    delayMotionCheck.start();
    countNoMotion = 0;
  }
}

void resumeMotionCheck() {
  //println("resumeMotionCheck: " +motionCheckEnabled); //<>//
  if(motionCheckEnabled) {
    delayMotionCheck.seek(0);
    motioncheckpaused = false;
    countNoMotion = 0;
  }
}


void startCapture() {
  if(slideShowRunning && !slideShowForced) {
    endSlideshow(); //<>//
    return;
  }
  if(!countdownrunning && !aftercapturerunning && !showcapturerunning) {
    countdownrunning = true;
    coundownnum = 3;
    runCountdown();
  } else if(countdownrunning && !aftercapturerunning && !showcapturerunning) {      // countdown abbrechen
    aniCountdownscale.pause();
    aniCountdownfade.pause();
    aniCountdownstroke.pause();
    aniCountdownscale.seek(0);
    aniCountdownfade.seek(0);
    aniCountdownstroke.seek(0);  
    countdownrunning = false;
    countdownstopped = true;
    countdownstoppedscale = 1.0;
    aniCountdownstopped.setBegin(countdownstoppedscale);
    aniCountdownstopped.start();
  }
}
      
      
void captureImage() {
  countdownstroke = 10;
  if(!firstrun) {
    countdownrunning = false;
    timestamp = generateTimestamp();
    captureNow = true;
  } else {
    firstrun = false; 
  }
}

void runCountdown() {
  if(countdownrunning) {
    if(coundownnum == 3) {
      cdsvg = cd3;
      aniCountdownstroke.start();
    } else if(coundownnum == 2) {
      cdsvg = cd2;
    } else if(coundownnum == 1) {
      cdsvg = cd1;
    } else {
      return;
    }
    countdownscale = 0.2;
    countdownfade = 0;
    aniCountdownscale.start();  
    aniCountdownfade.start();  
    coundownnum--;
  }
}

void endCaptureImage() {
  aftercapturerunning = false;
  aftercapturealpha = 255;
}

void endShowCapture() {
  showcapturerunning = false;
  showcapturealpha = 255;
}

void countdownstoppedEnd() {
  countdownstopped = false;
}

void showHelpText() {
  showfps = !showfps;
}


//--- IMG SELECTION -------------------------------------=====================================================

void showNext() { 
  if(!slideShowForced) {
    preloadNext();
    animNext();
  }
}

void showPrev() {
  if(!slideShowForced) {
    preloadPrev();
    animPrev();
  }
}


 void animNext() {
   if(waitforfade || fadeinrunning) {
     //Ani.killAll();
     aniWaitForFade.pause();
     aniWaitForFade.seek(0);
     aniAlphafade.pause();
     aniAlphafade.seek(0);
     waitforfade = false;
     fadeinrunning = false;
     animsJustStopped = false;
   }
   
   fadealpha = 255;
   
   if((animrunning && animDir) || !animrunning) {
     animDir = true;
     iianimoffset++;
     iianim = iigetadd(iianimoffset);
     images[iianim].aniStart(animDir);
     animrunning = true;
   } else {
      println("DIRCHANGE: forward to backward"); 
   }
 } 

 void animPrev() {
   if(waitforfade || fadeinrunning) {
     //Ani.killAll();
     aniWaitForFade.pause();
     aniWaitForFade.seek(0);
     aniAlphafade.pause();
     aniAlphafade.seek(0);
     waitforfade = false;
     fadeinrunning = false;
     animsJustStopped = false;
   }
   
   fadealpha = 255;
   
   if((animrunning && !animDir) || !animrunning) {   
     animDir = false;
     iianimoffset++;
     iianim = iigetsub(iianimoffset-1);
     images[iianim].aniStart(animDir);
     animrunning = true;  
   } else {
      println("DIRCHANGE: backward to forward"); 
   }
   

 }

public void reportMoveFinished(BlendImage bi, boolean forward) {
  
  iianimoffset--;
  
  if(forward) {
    iiincr();
    //println("iiincr(): " +ii);
  } else {
    iidecr();
    //println("iidecr(): " +ii);
  }
  
  liveimg = false;
  
  if(iianimoffset == 0) {
    animrunning = false;
    waitforfade = true;
    aniWaitForFade.start();
    //Ani.to(this, 1.0, "dummyval", 0, Ani.LINEAR, "onEnd:reportAnimFinished"); 
    
  }  
}

 public void reportAnimFinished() {
     animsJustStopped = true; 
 }

  public void fadeinFinished() {   
    fadeinrunning = false;
  }
  
  
//--- PRELOAD -------------------------------------

void preloadNext() {
  for(int p=1; p<=preloadnum; p++) {
    images[iigetadd(p)].load();
  }
}

void preloadPrev() {
  for(int p=1; p<=preloadnum; p++) {
    images[iigetsub(p)].load();
  }
}

// ---------------------------------------------------------------------------
//  INPUT EVENTS
// ---------------------------------------------------------------------------

void keyPressed() {  
  processKey(keyCode, true);
  
    if (keysDown[RIGHT]) {
      showNext();
    } else if (keysDown[LEFT]) {
      showPrev();
    } else if (keysDown['S']) {
      startCapture();
    } else if (keysDown['H']) {
      showHelpText();
    } else if (keysDown[' ']) {
      captureMode = !captureMode;
      countNoMotion = -1;
      if(!captureMode) {
        //motionCheckEnabled = false;
        slideShowForced = true;
        startSlideshow(); 
      } else {
        //motionCheckEnabled = true;
        slideShowForced = false;
        endSlideshow(); 
      }
      //captureMode = !captureMode;
    }
    if(motionCheckEnabled)
       pauseMotionCheck();
}

void keyReleased() {
  processKey(keyCode, false);
}
static void processKey(int k, boolean set) {
  if (k < KEYS)  keysDown[k] = set;
}

void mousePressed() {
  if (mouseButton == LEFT) {
  } else if (mouseButton == RIGHT) {
    startCapture();
  } else if (mouseButton == CENTER) {
  }
  if(motionCheckEnabled)
     pauseMotionCheck();
}

int mousewheel, mousewheelbefore;
int countMouseWheelEvents = 0;
int lastt, t, tdiff;
int debounce = 150;
float laste, e;

void mouseWheel(MouseEvent event) {
  //if(countMouseWheelEvents % 2 == 0) {
    //laste = e;
    e = event.getCount();
    
    lastt = t;
    t = millis();
    tdiff = t-lastt;

  /* //aussreisser
  if(   ((laste < 0f) && (e > 0f)) || 
        ((laste > 0f) && (e < 0f)) ) {
          if (tdiff < 500) {
            println("CORRECT e: " +e +" laste: " +laste );
            e = laste;
          }
  }
  */ 
  if(tdiff >= debounce) {   
    if (e < 0f) {
      //println("WHEEL R: " +e +" allowed: " +dirChangePossible +" " +frameCount);
      showPrev();
    } else {
      //println("WHEEL L: " +e +" allowed: " +dirChangePossible +" " +frameCount);
      showNext();
    }
  } else {
   t = tdiff; 
  }
  if(motionCheckEnabled)
     pauseMotionCheck();
  //}
  countMouseWheelEvents++;
}



// ---------------------------------------------------------------------------
//  GENERAL UTIL
// ---------------------------------------------------------------------------

//boolean sketchFullScreen() {
//  return fullscreen;
//}

int iigetadd(int n) {
  int tmp = ii + n;
  if(tmp >= images.length) {
     //tmp = tmp - images.length;
     tmp = tmp % images.length;
  }
  return tmp;
}

int iigetsub(int n) {
  int tmp = ii - n;
  if(tmp < 0) {
    tmp = tmp + images.length;
  }  
  return tmp;
}

int iiincr() {
  ii = (ii < images.length-1) ? ++ii : 0;
  return ii;
}
int iidecr() {
  ii = (ii > 0) ? --ii : images.length-1;
  return ii;
}

String generateTimestamp() {
  return year() +"" +nf(month(), 2) +"" +nf(day(), 2) +"" +"-" +nf(hour(), 2) +"" +nf(minute(), 2) +"" +nf(second(), 2);  
}


BlendImage[] getBlendImages() {
  String[] allFiles = {};
  File dir = new File(sketchPath("") +imgpath);
  if (dir.isDirectory()) {
    allFiles = dir.list();
  } else { exit(); }  
  
  ArrayList<BlendImage> tmplist = new ArrayList<BlendImage>();
  
  for (int k = 0; k < allFiles.length; k++) {
    String file = allFiles[k];
    if( file.toLowerCase().endsWith(".jpg") || 
        file.toLowerCase().endsWith(".png") ||
        file.toLowerCase().endsWith(".gif")) {
      tmplist.add(new BlendImage(imgpath +file));
    }
  }
  allFiles = null;
  Collections.shuffle(tmplist); 
  println("Found " +tmplist.size() +" usable images.");
  return tmplist.toArray(new BlendImage[tmplist.size()]);
}