'''
A basic model of the Equatorie in Pygame with Python3
'''

import math,sys
import pygame
from pygame.locals import *

pygame.init()
screen = pygame.display.set_mode((640, 480))

class Equatorie():
  def __init__(self):
    self.face_radius = 100
    self.face_width = 8
    self.face_pos = (320,240) # Also the point of the Earth - centre
    self.green_angle = 45 # angle of first string in degrees - the Mean Motus in effect (where it meets the edge face)
    self.equant = (self.face_pos[0] + 20, self.face_pos[1] - 20) # The Equant depends on the planet in question
    self.deferent = (self.face_pos[0] +(( self.equant[0] -self.face_pos[0] ) / 2), 
              self.face_pos[1] + ((self.equant[1] - self.face_pos[1] ) / 2) ) # Deferent is halfway between Earth and Equant

    self.epi_radius = 80
    self.epi_width =4
    self.epi_pos = (0,0)

  def draw(self,surf):
    '''Equatorie draw and setup function '''

    # Draw face of equatorie
    pygame.draw.circle(surf, (150,150,150), self.face_pos, self.face_radius, self.face_width)


    # Draw the green string
    r = math.radians(self.green_angle)
    end_pos = ( self.face_pos[0] + int(math.floor(self.face_radius * 2 * math.cos(r))), 
                self.face_pos[1] + int(math.floor(self.face_radius * 2 * math.sin(r))) )
    
    pygame.draw.line(surf, (0,255,0), self.face_pos, end_pos, self.face_width / 2)

    # y = mx + c - m being slope and c being y intercept
    m = math.sin(r) / math.cos(r)
    c = self.equant[1] - (m * self.equant[0])

    # Draw the white string
    end_pos = ( self.equant[0] + int(math.floor(self.face_radius * 2 * math.cos(r))), 
                self.equant[1] + int(math.floor(self.face_radius * 2 * math.sin(r))) )


    pygame.draw.line(surf, (255,255,255), self.equant, end_pos, self.face_width / 2)

  
    # Find the epicycle centre - quadratic equation of line / circle intersection - taken from Wolfram Alpha
    x1 = self.equant[0] - self.face_pos[0]
    x2 = end_pos[0] - self.face_pos[0]
    y1 = self.equant[1] - self.face_pos[1]
    y2 = end_pos[1] - self.face_pos[1]

    dx = x2 - x1
    dy = y2 - y1
    dr = math.sqrt(dx**2 + dy**2)

    D = x1*y2 - x2*y1

    s = -1
    if dy >= 0: s = 1

    x = ((D * dy) + (s * dx * math.sqrt((self.face_radius**2 * dr**2) - D**2) ) ) / (dr**2)

    x = int(math.floor(x + self.face_pos[0]))
    y = m * x + c
    y = int(math.floor(y))

    self.epi_pos = (x,y)

    # Find the rotation of the epicycle
    p0 = pygame.math.Vector2(0,1)

    p1 = pygame.math.Vector2(self.epi_pos[0] - self.deferent[0],self.epi_pos[1] - self.deferent[1])
    p1 = p1.normalize()

    r = math.asin(p1.dot(p0))

    print(math.degrees(r))

    # Draw deferent
    pygame.draw.circle(surf, (255,0,0), self.deferent, self.face_width / 3)

    # Draw equant
    pygame.draw.circle(surf, (255,255,0), self.equant, self.face_width / 3)

    # Draw Epicycle position
    pygame.draw.circle(surf, (0, 255,255), self.epi_pos, self.face_width / 3)

    # Draw Epicycle
    pygame.draw.circle(surf, (0, 255,255), self.epi_pos, self.epi_radius, self.epi_width)


if __name__ == "__main__":

  e = Equatorie()

  while 1:
    for event in pygame.event.get():
      if event.type in (QUIT, KEYDOWN):
        sys.exit()

    e.draw(screen)
    pygame.display.update()
    pygame.time.delay(100)