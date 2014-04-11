/* 
 *
 *
 */
import SimpleOpenNI.*; 
 
static final int KINECT_WIDTH = 640;
static final int KINECT_HEIGHT = 480;
 
SimpleOpenNI kinect;
 
// Grid 
PGraphics boardGrid;
PGraphics squareGrid;

// Sudoku
SudokuGame game;

// State
Board_View boardView;
int gridDisplayed;
int highlightedBoardGrid;

// Colors
color highlightedColor;
color inputColor;

void setup() {
  size(KINECT_WIDTH, KINECT_HEIGHT);   
  background(255); 
   
  initializeGrids();
  game = new SudokuGame();
  fillGrid();
  gridDisplayed = 0; // Entire board
  
  initializeColors();
  
  boardView = Board_View.ENTIRE;
  
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  
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
  } 
}

void fillGrid() {
  // Entire Grid
  if (boardView == Board_View.ENTIRE) {
    int[][] currentBoard = game.getBoard();
    boolean[][] originalNumbers = game.getOriginalNumbers();
    textSize(26);
    int currX = 138;
    int currY = 76;
    for (int i = 0; i < 9; i++) {
      currX = 138;
      for (int j = 0; j < 9; j++) {
        if (currentBoard[j][i] != 0) { // Do not fill empty cells
          if (originalNumbers[j][i]) {
            fill(inputColor);
          } else {
            fill(0, 0, 0);  
          }
          text(Integer.toString(currentBoard[j][i]), currX + j*44, currY);     
        }
      }
      currY += 44;  
    }
  } else if (boardView == Board_View.GRID && gridDisplayed > 0) {
    if (gridDisplayed < 4) {  
       int startCol = (gridDisplayed-1)*3;
       int endCol = startCol + 3;
       for (int i = 0; i < 3; i++) {
         for (int j = startCol; j < endCol; j++) {
           
         }  
       }
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

  squareGrid.beginDraw();
  squareGrid.stroke(0, 0, 0);
  squareGrid.strokeWeight(3);
  
  // Draw vertical lines
  squareGrid.line(164, 84, 164, 396);
  squareGrid.line(268, 84, 268, 396);
  squareGrid.line(372, 84, 372, 396);
  squareGrid.line(476, 84, 476, 84);
  
  squareGrid.endDraw();

}

void initializeColors() {
  highlightedColor = color(255, 255, 153);
  inputColor = color(0, 0, 255);
}



