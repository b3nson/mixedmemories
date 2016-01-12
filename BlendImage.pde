
public class BlendImage {
  
  private PImage img;
  private String imgpath;
  private int dispw, disph, dispy;
  private boolean loaded = false;
  private boolean requested = false;
  
  private boolean animrunning = false;
  private boolean lastAniDirection;
  private float anival;

  private float anistartval = 20;
  private float aniendval = 0;

  private Ani inAni, outAni;
  
  public BlendImage(String path) {
    imgpath = path;
    inAni =  Ani.to(this, 0.6, "anival", aniendval, Ani.SINE_IN_OUT, "onEnd:inAniFinished"); 
    outAni = Ani.to(this, 0.6, "anival", anistartval, Ani.SINE_IN_OUT, "onEnd:inAniFinished");  
  }
  
  
  
  public void draw() {
    pushMatrix(); 
    translate(dispw/2.0, disph/2.0 + dispy); //center img
    
    if(animrunning) {
      translate(0, height*6);
      rotate(radians(anival));    
      translate(0, -height*6);
      scale( map(abs(anival), aniendval, anistartval, 1.0f, 0.6f) );
    }
 
    if(loaded) {
      imageMode(CENTER);
      image(img, 0, 0, dispw, disph);
    } else {
      if(requested) {
        if((img.width != 0) && (img.width != -1)) {
          dispw = width;
          disph = (int)(((float)dispw/(float)img.width)*img.height);
          dispy = (int)((height - disph) / 2.0);
          loaded = true;
          requested = false;
        } else { //requested but not yet loaded
          imageMode(CENTER);
          image(dummy, width/2, height/2, width, height); 
        }
      } else { //not even requested
        load(); 
      }
    }
    popMatrix();
  }
  
  public void aniStart(boolean forward) {
    if(!animrunning || (animrunning && forward != lastAniDirection)) {
      
      if(animrunning) {
        println("ANI-DIRCHANGE");
        inAni.end();
        outAni.end();
      }
      
      lastAniDirection = forward;
      animrunning = true;
      
      //reindrehen
      if(lastAniDirection) {
        anival = anistartval;
        inAni.setBegin(anival);
        inAni.setEnd(aniendval);
        inAni.start();
      } else {
        anival = aniendval;
        outAni.setBegin(anival);
        outAni.setEnd(anistartval);
        outAni.start();
      }
    } else {
      //reportAnimFinished(this, lastAniDirection); 
      //aniFinished();
      //inAniFinished();
    }
  }

 private void inAniFinished() {
   animrunning = false;
   reportMoveFinished(lastAniDirection);
 }
 
 private void aniFinished() {
   //println("aniFinished");
   //animrunning = false;
   //reportAnimFinished(this, lastAniDirection);
 }
  
  PImage getImg() {
    if(loaded) {
      return img;
    } else {
     return dummy; 
    }
  }
  
  PVector getDisplaySize() {
    return new PVector(dispw, disph);
  }
  
  public void load() {
    if(!requested && !loaded) {
      img = requestImage(imgpath);
      requested = true;
    }
  }
 
} //class