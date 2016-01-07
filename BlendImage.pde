
public class BlendImage {
  
  private PImage img;
  private String imgpath;
  private int dispw, disph, dispy;
  private boolean loaded = false;
  private boolean requested = false;
  
  private boolean animrunning = false;
  private boolean lastAniDirection;
  private float anival;
  private float anival_x;
//  01
  private float anistartval = 20;
  private float aniendval = 0;

// 02
  //private float anistartval = 1920;
  //private float aniendval = 0;
  
  private float dummyval = 0f;
  private Ani inAni, outAni;
  
  public BlendImage(String path) {
    imgpath = path;
    inAni =  Ani.to(this, 0.6, "anival", aniendval, Ani.SINE_IN_OUT, "onEnd:inAniFinished"); 
    outAni = Ani.to(this, 0.6, "anival", anistartval, Ani.SINE_IN_OUT, "onEnd:inAniFinished");  
  }
  
  
  
  public void draw() {

    pushMatrix(); 
      translate(dispw/2.0, disph/2.0 + dispy); //center img
      //reindrehen
      
      if(animrunning) {
          // 02
          //scale( map(abs(anival), aniendval, anistartval, 1.0f, 1.35f) );        
          //translate(anival, 0);
          
          //tint(255, map(anival, 0, width, 255, 0)); //noTint!!
          
          
//01        
        translate(0, height*6);
        rotate(radians(anival));    
        translate(0, -height*6);
                scale( map(abs(anival), aniendval, anistartval, 1.0f, 0.6f) );



//01        
//        translate(0, height*6);
//        rotate(radians(anival));    
//        translate(0, -height*6);

    }
      
      
      //reinschieben
      /*
      if(animrunning) {
        translate(anival_x, 0);
      }    
      */
      
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
          
//          overlay.set("imgSampler", images[ii].getImg());
//          overlay.set("camscalex", ( (float)images[ii].getDisplaySize().x) / (float)width);  
//          overlay.set("camscaley", ( (float)images[ii].getDisplaySize().y) / (float)height); 
          
        } else { //requested but not yet loaded
          imageMode(CENTER);
          image(dummy, width/2, height/2, width, height); 
        }
      } else { //not even requested
        load(); 
      }
    }
    
    popMatrix();
    //noTint();
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
      //anival = lastAniDirection ? abs(anistartval) : -anistartval;
      if(lastAniDirection) {
        anival = anistartval;
        inAni.setBegin(anival);
        inAni.setEnd(aniendval);
        inAni.start();
        //Ani.to(this, 0.6, "anival", aniendval, Ani.SINE_IN_OUT, "onEnd:inAniFinished");  
      } else {
        anival = aniendval;
        outAni.setBegin(anival);
        outAni.setEnd(anistartval);
        outAni.start();
        //Ani.to(this, 0.6, "anival", anistartval, Ani.SINE_IN_OUT, "onEnd:inAniFinished");  
      }
      
      //reinschieben
        //anival_x = lastAniDirection ? width : -width;;
        //Ani.to(this, 0.6, "anival_x", aniendval_x, Ani.SINE_IN_OUT, "onEnd:inAniFinished"); 

    } else {
      //reportAnimFinished(this, lastAniDirection); 
      //aniFinished();
      //inAniFinished();
    }
  }

 private void inAniFinished() {
   animrunning = false;
   reportMoveFinished(this, lastAniDirection);
   //Ani.to(this, 1.0, "dummyval", 0, Ani.LINEAR, "onEnd:aniFinished"); 
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
      //println("loading: " +imgpath);
      img = requestImage(imgpath);
      requested = true;
    }
  }
  
  
  public void print() {
   println("BlendImage----------"); 
   println(imgpath); 
   println("--------------------"); 
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
} //class
