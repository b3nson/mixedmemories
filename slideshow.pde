StringList slideshowList;
PImage slideCur, slideNxt, slideLod;
int slideShowIndex = 0;
float alpha = 0f;

boolean transitionRunning = false;
boolean firstRunAfterLoad = false;
boolean slideShowStarted = false;
boolean slideShowRunning = false;
boolean slideShowForced = false;
boolean startFadeIn = false;

float slideDuration = 5f;
float transDuration = 2f;

Ani slidetrans, slidetime ;


void drawSlideshow() {

  if(slideShowStarted) {
    if((slideCur.width != 0) && (slideCur.width != -1) &&
       (slideNxt.width != 0) && (slideNxt.width != -1)) {
        slideShowRunning = true;
        slideShowStarted = false;
        startFadeIn = true;
        alpha = 0;
        Ani.autostart();
        Ani.to(this, transDuration, "alpha", 255, Ani.SINE_IN_OUT);
        Ani.to(this, slideDuration, transDuration, "dummyval", 0, Ani.LINEAR, "onEnd:showNextSlide"); 
        Ani.noAutostart();
     }
  }
  
  if(slideShowRunning) {
    colorMode(RGB, 255, 255, 255, 255);
    pushMatrix();
      translate(w/2, h/2);
      if(transitionRunning && isNextReady()) {   //show transition (2ximg)
        if(firstRunAfterLoad) {
           alpha = 0f;
           slidetrans.setBegin(alpha);
           slidetrans.setDuration(transDuration);
           slidetrans.start();
           firstRunAfterLoad = false;
        }
        noTint();
        image(slideCur, 0, 0, w, h);
        tint(255, alpha);
        image(slideNxt, 0, 0, w, h);
      } 
      
      else {                                 //just show current img
        if(startFadeIn) {                    //fadeIn on Slideshow Start
          tint(255, alpha);
        }
        image(slideCur, 0, 0, w, h);
        noTint();
      }
      fill(0,255,0);
      stroke(green);
      strokeWeight(10);
      noFill();
      rect(-w/2,-h/2,w,h);
    popMatrix();
  }
}


void startSlideshow() {
  Ani.noAutostart();
  slidetrans = new Ani(this, transDuration, "alpha", 255, Ani.SINE_IN_OUT, "onEnd:transComplete");
  slidetime  = new Ani(this, slideDuration, "dummyval", 0, Ani.LINEAR, "onEnd:showNextSlide");
  slideshowList = getSlideshowImages();
  
  if(slideshowList.size() > 1) {
    slideShowIndex = 0;
    slideShowStarted = true;
    firstRunAfterLoad = true;
    slideCur = requestImage(slideshowList.get(slideShowIndex));
    slideNxt = requestImage(slideshowList.get(slideShowIndex+1));
    loadNextSlide();
    println("START SLIDESHOW");
  } else {
    slideshowList = null;
    slideShowForced = false;
    endSlideshow();
  }
}

void endSlideshow() {
  slideShowRunning = false;
  slideshowList = null; //<>//
  slideCur = null;
  slideNxt = null;
  slideLod = null;
  slidetime.pause();
  slidetime.seek(0f);
  slidetrans.pause();
  slidetrans.seek(0f);
  if(startFadeIn) {
      Ani.killAll();
  }
  println("END SLIDESHOW");
}


void transComplete() {
  transitionRunning = false;
  slideShowIndex = (slideShowIndex+1 < slideshowList.size()) ? slideShowIndex+1 : 0;
  slideCur = slideNxt;
  slideNxt = slideLod;
  slideLod = null;
  slidetime.setDuration(slideDuration);
  slidetime.start();
}


void showNextSlide() {
  println("slideshow: showNextSlide()");
  startFadeIn = false;
  transitionRunning = true;
  firstRunAfterLoad = true;
  loadNextSlide();
}

void loadNextSlide() {
  int tmpi = (slideShowIndex+2 < slideshowList.size()) ? slideShowIndex+2 : slideShowIndex+2 - slideshowList.size();
  slideLod = requestImage(slideshowList.get(tmpi));
}

boolean isNextReady() {
  if((slideNxt.width != 0) && (slideNxt.width != -1)) {
    return true;
  } else {
    return false;
  }
}

StringList getSlideshowImages() {
  String[] allFiles = {};
  File dir = new File(sketchPath("") +oPath);
  if (dir.isDirectory()) {
    allFiles = dir.list();
  } else { exit(); }  
  
  StringList tmplist = new StringList();
  
  for (int k = 0; k < allFiles.length; k++) {
    String file = allFiles[k];
    if( file.toLowerCase().endsWith(".tga") || 
        file.toLowerCase().endsWith(".tif")) {
      tmplist.append((oPath +file));
    }
  }
  tmplist.shuffle();
  println("Found " +tmplist.size() +" usable images.");
  return tmplist;
}