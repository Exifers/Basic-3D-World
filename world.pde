import java.awt.*;
import java.awt.event.*;

Robot robot;

PVector pos;
PVector vel;
PVector lookDir;
int[] keysPressed;
float[][] alt;

int n=50;
float scale=5;
float detail=0.015;
float maxAlt=200*scale;
float tile=20*scale;

PImage img;
PImage sky;

void setup() {
  fullScreen(P3D);
  //size(600,600,P3D);
  noCursor();
  robot = initRobot();
  keysPressed = new int[0];
  pos = new PVector(0, 0, 500);
  vel = new PVector(0, 0, 0);
  lookDir = new PVector(1, 1, -1);
  alt = new float[n][n];
  for (int i=0; i<n; i++) {
    for (int j=0; j<n; j++) {
      alt[i][j]=noise(i*detail, j*detail);
    }
  }
  img = loadImage("text.png");
  sky = loadImage("sky.png");
  sky.resize(width, height);
}

void draw () {
  background(0);
  lightFalloff(1, 0, 0.000000005);
  //pointLight(255, 255, 255, 0, 0, maxAlt+50);
  //pointLight(255, 255, 255, 0, 0, -maxAlt+50);

  pushMatrix();
  translate(n*tile/2, n*tile/2, 1.05*maxAlt+0.2*maxAlt*cos(frameCount*0.02));
  sphere(10);
  pointLight(255, 255, 255, 0, 0, 0);
  popMatrix();

  noStroke();
  for (int i=0; i<n-1; i++) {
    beginShape(TRIANGLE_STRIP);
    texture(img);
    for (int j=0; j<n; j++) {
      vertex(i*tile, j*tile, alt[i][j]*maxAlt, img.width*i/(n-1), img.height*j/n);
      vertex((i+1)*tile, j*tile, alt[i+1][j]*maxAlt, img.width*(i+1)/(n-1), img.height*j/n);
    }
    endShape();
  }
  endShape();

  updatePos();
  updateCamera();
}

void keyPressed() {
  keysPressed = append(keysPressed, keyCode);
}

void keyReleased() {
  int[] remain = new int[0];
  for (int i=0; i<keysPressed.length; i++) {
    if (keysPressed[i]!=keyCode) {
      remain = append(remain, keysPressed[i]);
    }
  }
  keysPressed = remain;
}

void updateCamera() {
  if (mouseX == 0) {
    robot.mouseMove(width-2, mouseY);
  }
  if (mouseX == width-1) {
    robot.mouseMove(1, mouseY);
  }

  float theta = 2*PI*(mouseX-(width-2)/2)/(width-2);
  float phi = -PI*(mouseY-height/2)/height;
  float x = cos(phi)*cos(theta);
  float y = cos(phi)*sin(theta);
  float z = sin(phi);
  lookDir = new PVector(x, y, z);
  lookDir.mult(10);

  camera(pos.x, pos.y, pos.z, pos.x+lookDir.x, pos.y+lookDir.y, pos.z+lookDir.z, 0, 0, -1);
}

void updatePos() {
  PVector friction = new PVector(0, 0, 0);
  friction.sub(vel);
  friction.mult(0.5);
  vel = new PVector(vel.x + friction.x, vel.y + friction.y, vel.z);
  PVector force = new PVector(0, 0, 0);
  if (isPressed(87)) {
    force.add(new PVector(lookDir.x, lookDir.y, 0));
  }
  if (isPressed(83)) {
    force.add(new PVector(-lookDir.x, -lookDir.y, 0));
  }
  if (isPressed(65)) {
    force.add(new PVector(lookDir.y, -lookDir.x, 0));
  }
  if (isPressed(68)) {
    force.add(new PVector(-lookDir.y, lookDir.x, 0));
  }
  if (isPressed(16)) {
    force.add(new PVector(0, 0, -1).mult(sqrt(pow(lookDir.x, 2)+pow(lookDir.y, 2))));
  }
  force = force.normalize().mult(8);
  if (isPressed(32)) {
    if (0 <= pos.x && pos.x <= tile*(n-1)) {
      if (0 <= pos.y && pos.y <= tile*(n-1)) {
        if (pos.z > 600 + getAlt(pos)*maxAlt) {
          force.add(new PVector(0, 0, 10)).mult(sqrt(pow(lookDir.x, 2)+pow(lookDir.y, 2)));
        }
      }
    }
    //force.add(new PVector(0, 0, 10).mult(sqrt(pow(lookDir.x, 2)+pow(lookDir.y, 2))));
  }
  // gravity
  if (0 <= pos.x && pos.x <= tile*(n-1)) {
    if (0 <= pos.y && pos.y <= tile*(n-1)) {
      if (pos.z > 600 + getAlt(pos)*maxAlt) {
        force.add(new PVector(0, 0, -12));
      }
    }
  }
  vel.add(force);
  pos.add(vel);
  if (0 <= pos.x && pos.x <= tile*(n-1)) {
    if (0 <= pos.y && pos.y <= tile*(n-1)) {
      if (pos.z < 600 + getAlt(pos)*maxAlt) {
        pos.z = 600 + getAlt(pos)*maxAlt;
      }
    }
  }
}

Boolean isPressed(int _keyCode) {
  for (int i=0; i<keysPressed.length; i++) {
    if (keysPressed[i]==_keyCode) {
      return true;
    }
  }
  return false;
}

Robot initRobot() {
  try
  {
    return new Robot();
  }
  catch (AWTException e)
  {
    println("Robot class not supported by your system!");
    exit();
  }
  return null;
}

float getAlt(PVector pos) {
  int _x = floor(pos.x/tile);
  int _y = floor(pos.y/tile);
  if (pos.x - floor(pos.x) + pos.y - floor(pos.y) >= tile) {
    float z1 = alt[_x+1][_y];
    float z2 = alt[_x][_y+1];
    float z3 = alt[_x+1][_y+1];

    PVector a = new PVector(-tile, tile, z2-z1);
    PVector b = new PVector(0, tile, z3-z1);
    PVector n = a.cross(b);
    return z1 + (n.x*((_x+1)*tile - pos.x)+n.y*(_y - pos.y))/n.z;
  } else {
    float z1 = alt[_x][_y];
    float z2 = alt[_x+1][_y];
    float z3 = alt[_x][_y+1];

    PVector a = new PVector(tile, 0, z2-z1);
    PVector b = new PVector(0, tile, z3-z1);
    PVector n = a.cross(b);
    return z1 + (n.x*(_x*tile - pos.x)+n.y*(_y*tile - pos.y))/n.z;
  }
}