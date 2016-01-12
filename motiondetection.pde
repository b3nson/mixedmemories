PShader modect;  
PGraphics diffimg;
PImage prev;

boolean modect_preview = false;
boolean motioncheckpaused = true;
boolean firstcheck = true;
boolean motion = false;
int whitecount = 0;
int countNoMotion = -1;
float dummyval;
float modect_contrast = 5f;
int checkPauseDuration = 20;
int dectw = 256;
int decth = 144;
int maxNoMotion = 10;
int numHotPixels = 2;

void checkMotion() {
     if(firstcheck) {
       prev = cam.get(width/4, height/4, width/2, height/2);
       firstcheck = false;
     }
  
      modect.set("destSampler", cam.get(width/4, height/4, width/2, height/2));
      modect.set("srcSampler", prev);
      modect.set("contrast", modect_contrast);

      prev = cam.get(width/4, height/4, width/2, height/2);

      diffimg.shader(modect);
    
      diffimg.beginDraw();
      diffimg.pushMatrix();
        diffimg.translate(0, 0);
        diffimg.noStroke();
        diffimg.beginShape(QUAD);
        diffimg.vertex(0, 0, 0, 0);
        diffimg.vertex(dectw, 0, 1, 0);
        diffimg.vertex(dectw, decth, 1, 1);
        diffimg.vertex(0, decth, 0, 1);
        diffimg.endShape();
      diffimg.popMatrix();
      diffimg.endDraw();
              
      diffimg.resetShader();
      resetShader();
    
      diffimg.loadPixels();
      thread("detectMotion");
}

void detectMotion() {
  int whitecount = 0;
  int s = diffimg.pixels.length/2;
  int c;
  
  for(int i=0; i < s; i++) {
    c = (diffimg.pixels[s+i] >> 16) & 0xFF;
    if(c > 128) {
      whitecount++;
      if(whitecount >= numHotPixels) break;
    } 
    c = (diffimg.pixels[s-i] >> 16) & 0xFF;
    if(c > 128) {
      whitecount++;
      if(whitecount >= numHotPixels) break;
    } 
  }
   
  println("modect: analyse motion: " +whitecount);
  if(whitecount >= numHotPixels) {
    motion = true;
    pauseMotionCheck();
    countNoMotion = -1;
    firstcheck = true;
  } else {
    motion = false;
    countNoMotion++;
  }  
}