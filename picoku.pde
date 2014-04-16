/* 
 *  Picoku  
 *  Play Sudoku with a Pico projector and Windows Kinect
 *  by Brendan Fruin and Kristin Williams
 *
 *  Kinect uses SimpleOpenNI
 *  following Greg Borenstein's Making Things See
 */
 
import java.util.Map;
import SimpleOpenNI.*; 
import processing.serial.*;
 
static final int KINECT_WIDTH = 640;
static final int KINECT_HEIGHT = 480;
 
SimpleOpenNI kinect;
Serial port;
 
// Grid 
PGraphics boardGrid;
PGraphics squareGrid;

// Sudoku
SudokuGame game;

// State
Board_View boardView;
int gridDisplayed;
int highlightedBoardGrid;
int highlightedCell;
int highlightedNumber;

// Colors
color highlightedColor;
color highlightedCellColor;
color inputColor;

// Cells
int selectedRow;
int selectedCol;

int prevX;
int prevY;

// Hand
int handVecListSize = 20;
Map<Integer,ArrayList<PVector>> handPathList 
          = new HashMap<Integer,ArrayList<PVector>>();

int completedFrames;

void setup() {
  size(KINECT_WIDTH, KINECT_HEIGHT);   
  port = new Serial(this, Serial.list()[5], 9600);
  movePico(0);
  newGame();
  
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  kinect.enableHand();
  
  // Set gesture listeners
  kinect.startGesture(SimpleOpenNI.GESTURE_CLICK);
  kinect.startGesture(SimpleOpenNI.GESTURE_WAVE);
}

void newGame() {
  background(255); 
   
  initializeGrids();
  game = new SudokuGame();
  fillGrid();
  gridDisplayed = 0; // Entire board

  initializeColors();
  
  boardView = Board_View.ENTIRE;
  completedFrames = 0;
}
 
void draw() {
  kinect.update();

  int[] depthValues = kinect.depthMap();
  
  int closestValue = 8000;
  int closestX = 0;
  int closestY = 0;

  for (int y = 0; y < KINECT_HEIGHT; y++) {
    for (int x = 0; x < KINECT_WIDTH; x++) {
      int pixelIndex = x + (y * KINECT_WIDTH);
      int depthValue = depthValues[pixelIndex];
         
      if (depthValue > 0 && depthValue < closestValue) {
        closestValue = depthValue;
        closestX = x;
        closestY = y;
       }
     }
  }
  if (boardView == Board_View.ENTIRE) {
     // Redraw grid to remove previous dot
     background(255);
     setAndFillHighlightedBoardGrid(closestX, closestY);
     image(boardGrid, 0, 0);
     fillGrid();
     
     // Draw green circle at closest point
     fill(0, 255, 0);
     ellipse(closestX, closestY, 10, 10);
  } else if (boardView == Board_View.GRID) {
     background(255);
     setAndFillHighlightedSquareGrid(closestX, closestY);
     image(squareGrid, 0, 0);
     fillGrid();
     
     // Draw green circle at closest point
     fill(0, 255, 0);
     ellipse(closestX, closestY, 10, 10);
  } else if (boardView == Board_View.ENTRY) {
    background(255);
    highlightNumber(closestX, closestY);
    setAndFillHighlightedSquareGrid(closestX, closestY);
    image(squareGrid, 0, 0);
    fillGrid();
    drawInputNumbers();  
    // Draw green circle at closest point
    fill(0, 255, 0);
    ellipse(closestX, closestY, 10, 10);
  } else {  // RESET
    if (completedFrames > 50) {
      newGame();
    }
    completedFrames++;
  }
}

void fillGrid() {
  int[][] currentBoard = game.getBoard();
  boolean[][] inputNumbers = game.getInputNumbers();
  if (boardView == Board_View.ENTIRE) {
    textSize(26);
    int currX = 138;
    int currY = 76;
    for (int i = 0; i < 9; i++) {
      currX = 138;
      for (int j = 0; j < 9; j++) {
        if (currentBoard[j][i] != 0) { // Do not fill empty cells
          if (inputNumbers[j][i]) {
            fill(inputColor);
          } else {
            fill(0, 0, 0);  
          }
          text(Integer.toString(currentBoard[j][i]), currX + j*44, currY);     
        }
      }
      currY += 44;  
    }
  } else if ((boardView == Board_View.GRID || boardView == Board_View.ENTRY) && gridDisplayed > 0) {
    int[] rows;
    int[] cols;
    int startCol;
    if (gridDisplayed < 4) {  
      rows = new int[] {0, 1, 2};
      startCol = (gridDisplayed-1)*3;
    } else if (gridDisplayed < 7) {
      rows = new int[] {3, 4, 5};
      startCol = (gridDisplayed-4)*3;
    } else {
      rows = new int[] {6, 7, 8};
      startCol = (gridDisplayed-7)*3;
    }
    cols = new int[] {startCol, startCol+1, startCol+2};
    
    textSize(30);
    int currX = 205;
    int currY = 150;
    
    for (int i = 0; i < 3; i++) {
      currX = 205;
      for (int j = 0; j < 3; j++) {
        int row = rows[i];
        int col = cols[j];
        if(currentBoard[col][row] != 0) {
          if (inputNumbers[col][row]) {
            fill(inputColor); 
          } else {
            fill(0, 0, 0); 
          }
          text(Integer.toString(currentBoard[col][row]), currX + j*104, currY);
        }
      }
      currY += 104;  
    }
  }
}

void selectCell() {
  int[][] currentBoard = game.getBoard();
  boolean[][] inputNumbers = game.getInputNumbers();
  
  if (highlightedCell > 0) {
    if (inputNumbers[selectedRow][selectedCol]) {
      // can not update original number  
    } else {
      boardView = Board_View.ENTRY;
    }
  }
}

void setAndFillHighlightedBoardGrid(int x, int y) {
  if (x < 122 || x > 518 || y < 42 || y > 438) {
    highlightedBoardGrid = 0;
  } else {
    int startX;
    int startY;
    
    if (x < 254) { // 1, 4, 7
      startX = 122;
      if (y < 174) {
        highlightedBoardGrid = 1;
        startY = 42;
      } else if (y < 306) {
        highlightedBoardGrid = 4;  
        startY = 174;
      } else {
        highlightedBoardGrid = 7; 
        startY = 306;
      }
    } else if (x < 386) { // 2, 5, 8
      startX = 254;
      if (y < 174) {
        highlightedBoardGrid = 2;  
        startY = 42;
      } else if (y < 306) {
        highlightedBoardGrid = 5;
        startY = 174;  
      } else {
        highlightedBoardGrid = 8;
        startY = 306; 
      }
    } else { // 3, 6, 9
      startX = 386;
      if (y < 174) {
        highlightedBoardGrid = 3;  
        startY = 42;
      } else if (y < 306) {
        highlightedBoardGrid = 6;
        startY = 174;  
      } else {
        highlightedBoardGrid = 9; 
        startY = 306;
      }
    }
    
    fill(highlightedColor);
    rect(startX, startY, 132, 132);
  }  
}

void setAndFillHighlightedSquareGrid(int x, int y) {
  if (boardView == Board_View.ENTRY) {
    x = prevX;
    y = prevY;   
  }
  
  if (x < 164 || x > 476 || y < 84 || y > 396) {
    highlightedCell = 0;
    selectedRow = -1;
    selectedCol = -1; 
  } else {
    prevX = x;
    prevY = y;
    
    
    int startX;
    int startY;
    
    if (x < 268) { // 1, 4, 7
      startX = 164;
      if (y < 188) {
        highlightedCell = 1;
        startY = 84;
      } else if (y < 292) {
        highlightedCell = 4;  
        startY = 188;
      } else {
        highlightedCell = 7; 
        startY = 292;
      }
    } else if (x < 372) { // 2, 5, 8
      startX = 268;
      if (y < 188) {
        highlightedCell = 2;  
        startY = 84;
      } else if (y < 292) {
        highlightedCell = 5;
        startY = 188;  
      } else {
        highlightedCell = 8;
        startY = 292; 
      }
    } else { // 3, 6, 9
      startX = 372;
      if (y < 188) {
        highlightedCell = 3;  
        startY = 84;
      } else if (y < 292) {
        highlightedCell = 6;
        startY = 188;  
      } else {
        highlightedCell = 9; 
        startY = 292;
      }
    }
    
    fill(highlightedColor);
    rect(startX, startY, 104, 104);
    
    int[] rows;
    int[] cols;
    int startCol;
    
    if (gridDisplayed < 4) {  
      rows = new int[] {0, 1, 2};
      startCol = (gridDisplayed-1)*3;
    } else if (gridDisplayed < 7) {
      rows = new int[] {3, 4, 5};
      startCol = (gridDisplayed-4)*3;
    } else {
      rows = new int[] {6, 7, 8};
      startCol = (gridDisplayed-7)*3;
    }
    cols = new int[] {startCol, startCol+1, startCol+2};
  
    int row = (highlightedCell-1) / 3;
    int col = (highlightedCell-1) % 3;
    
    selectedRow = rows[row];
    selectedCol = cols[col];
    
    drawCellContext();
  }  
}
void highlightNumber(int x, int y) {
  if (x < 530) {
    highlightedNumber = -1;
  } else if (y < 240) { // clear, 1, 2, 3, 4
    if (y < 150) {
      if (y < 60) {
        highlightedNumber = 0;  
      } else if (y < 105) {
        highlightedNumber = 1; 
      } else {
        highlightedNumber = 2; 
      }
    } else {
      if (y < 195) {
        highlightedNumber = 3;  
      } else {
        highlightedNumber = 4;
      }
    }
  } else { // 5, 6, 7, 8, 9
    if (y < 375) {
      if (y < 285) {
        highlightedNumber = 5;
      } else if (y < 330) {
        highlightedNumber = 6;  
      } else {
        highlightedNumber = 7;
      }
    } else {
      if (y < 420) {
        highlightedNumber = 8;    
      } else {
        highlightedNumber = 9;
      }
    }
  }
}

void drawCellContext() {
  int currX = 15;
  int currY = 172;
  
  int[][] currentBoard = game.getBoard();
  boolean[][] inputNumbers = game.getInputNumbers();
  
  textSize(14);
  for (int i = 0; i < 9; i++) {
    currX = 15;
    for (int j = 0; j < 9; j++) {
      if (selectedRow == i && selectedCol == j) {
        fill(highlightedCellColor);
      } else {
        fill(255, 255, 255);  
      }
      
      if (selectedRow == i || selectedCol == j) {
        rect(currX + j*15, currY, 15, 15); 
        if (currentBoard[j][i] > 0) {
          if (inputNumbers[j][i]) {
            fill(inputColor);
          } else {
            fill(0, 0, 0); 
          }
          text(Integer.toString(currentBoard[j][i]), currX + j*15 + 3, currY+15);
        }
      }
    }
    currY += 15;  
  }
  
}

void drawInputNumbers() {
  textSize(35);
 
  String possibilities[] = {"clear", "1", "2", "3",
                            "4", "5", "6", "7",
                            "8", "9"};
  
  if (highlightedNumber == 0) {
    fill(255, 0, 0);  
  } else {
    fill(0, 0, 0); 
  }
  text(possibilities[0], 530, 40);
  for (int i = 1; i < possibilities.length; i++) {
    if (i == highlightedNumber) {
      fill(255, 0, 0);
    } else {
      fill(0, 0, 0); 
    }
    text(possibilities[i], 558, 40*(i+1) + i*5);
  }
}


// Hand Events
void onNewHand(SimpleOpenNI curContext,int handId,PVector pos)
{
  println("onNewHand - handId: " + handId + ", pos: " + pos);
 
  ArrayList<PVector> vecList = new ArrayList<PVector>();
  vecList.add(pos);
  
  handPathList.put(handId,vecList);
}

void onTrackedHand(SimpleOpenNI curContext,int handId,PVector pos)
{
  //println("onTrackedHand - handId: " + handId + ", pos: " + pos );
  
  ArrayList<PVector> vecList = handPathList.get(handId);
  if(vecList != null)
  {
    vecList.add(0,pos);
    if(vecList.size() >= handVecListSize)
      // remove the last point 
      vecList.remove(vecList.size()-1); 
  }  
}

void onLostHand(SimpleOpenNI curContext,int handId)
{
  println("onLostHand - handId: " + handId);
  handPathList.remove(handId);
}

void displayCongratulations() {
    background(255);
    setAndFillHighlightedBoardGrid(0, 0);
    image(boardGrid, 0, 0);
    fillGrid();
  
    textSize(40);
    fill(0, 0, 255);
    text("Congratulations!", KINECT_WIDTH/2 - 150, KINECT_HEIGHT/2);
}

// Move pico left (-1), neutral (0) or right (1)
void movePico (int direction) {
  println("Move pico " + direction);
  if (direction < 0) {
    port.write(0);
  } else if (direction == 0) {
    port.write(62);
  } else {
    port.write(125);
  }  
}

// Gesture Event
void onCompletedGesture(SimpleOpenNI curContext,int gestureType, PVector pos)
{
  println("onCompletedGesture - gestureType: " + gestureType + ", pos: " + pos);
  if (gestureType == SimpleOpenNI.GESTURE_CLICK) {
    if (boardView == Board_View.ENTIRE) {
      if (highlightedBoardGrid > 0) {
        gridDisplayed = highlightedBoardGrid;
        boardView = Board_View.GRID;
        highlightedNumber = -1;
        if ((highlightedBoardGrid-1) % 3 == 0) { // Move pico to left
          movePico(-1);
        } else if ((highlightedBoardGrid-3) % 3 == 0) { // Move pico to right
          movePico(1);
        }
      }  
    } else if (boardView == Board_View.GRID) {
      selectCell();
    } else if (boardView == Board_View.ENTRY) {
      game.setNumber(selectedRow, selectedCol, highlightedNumber);
      highlightedNumber = -1;
      if (game.checkGameCompleted()) {
        movePico(0);
        displayCongratulations();
        boardView = Board_View.RESET;
      } else {
        boardView = Board_View.GRID;  
      }
    }
  } else if (gestureType == SimpleOpenNI.GESTURE_WAVE) {
    if (boardView == Board_View.ENTIRE) {
       // do something  
    } else if (boardView == Board_View.GRID) {
      movePico(0);
      boardView = Board_View.ENTIRE;
      gridDisplayed = 0;
      highlightedBoardGrid = 0;    
    } else if (boardView == Board_View.ENTRY) {
      boardView = Board_View.GRID;  
    }
  } 
  
  int handId = kinect.startTrackingHand(pos);
  println("hand stracked: " + handId);
}



// Initialization
void initializeGrids() {
  boardGrid = createGraphics(KINECT_WIDTH, KINECT_HEIGHT);
  boardGrid.beginDraw();
  boardGrid.stroke(0, 0, 0);
  boardGrid.strokeWeight(3);
  
  // Draw vertical lines
  boardGrid.line(122, 42, 122, 438);
  boardGrid.line(254, 42, 254, 438);
  boardGrid.line(386, 42, 386, 438);
  boardGrid.line(518, 42, 518, 438);
  
  // Draw horizontal lines
  boardGrid.line(122, 42, 518, 42);
  boardGrid.line(122, 174, 518, 174);
  boardGrid.line(122, 306, 518, 306);
  boardGrid.line(122, 438, 518, 438);
  
  boardGrid.beginDraw();
  boardGrid.stroke(0, 0, 0);
  boardGrid.strokeWeight(1);
  for (int i = 166; i < 518; i += 44) {
    if ((i-122) % 132 != 0) { // Don't redraw lines
      boardGrid.line(i, 42, i, 438);
    }  
  }
  
  for (int i = 86; i < 482; i+= 44) {
    if ((i-42) % 132 != 0) {
      boardGrid.line(122, i, 518, i); 
    } 
  }

  boardGrid.endDraw();

  squareGrid = createGraphics(KINECT_WIDTH, KINECT_HEIGHT);
  squareGrid.beginDraw();
  squareGrid.stroke(0, 0, 0);
  squareGrid.strokeWeight(3);
  
  // Draw vertical lines
  squareGrid.line(164, 84, 164, 396);
  squareGrid.line(268, 84, 268, 396);
  squareGrid.line(372, 84, 372, 396);
  squareGrid.line(476, 84, 476, 396);
  
  squareGrid.line(164, 84, 476, 84);
  squareGrid.line(164, 188, 476, 188);
  squareGrid.line(164, 292, 476, 292);
  squareGrid.line(164, 396, 476, 396);
  
  squareGrid.endDraw();

}

void initializeColors() {
  highlightedColor = color(255, 255, 153);
  highlightedCellColor = color(255, 153, 102);
  inputColor = color(0, 0, 255);
}



